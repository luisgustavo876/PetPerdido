/**
 * Cloud Functions do PetPerdido.
 *
 * alertarProximos: quando um post é criado, avisa (push FCM + registro em
 * users/{uid}/notifications) quem está perto, conforme o raio de cada um.
 *
 * analisarPet: o app manda a foto (ou a descrição) do pet e recebe as
 * sugestões da IA (Gemini). A chave do Gemini fica num segredo do Firebase,
 * nunca no app.
 */
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onRequest} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {geohashQueryBounds} = require("geofire-common");
const {
  RAIO_MAXIMO_KM,
  escolherDestinatarios,
  montarMensagem,
  montarPush,
  tokenInvalido,
  emLotes,
} = require("./alertas");
const {
  MODELOS,
  validarEntrada,
  montarRequisicao,
  extrairTexto,
  tentarProximoModelo,
} = require("./ia");

// Chave do Gemini (projeto separado, no nível gratuito). Gravada com
// `firebase functions:secrets:set GEMINI_API_KEY`.
const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

// Modo de teste dos alertas (functions/.env): true = todo post novo avisa
// TODOS os usuários, inclusive o autor, sem olhar a distância.
const ALERTAS_PARA_TODOS = process.env.ALERTAS_PARA_TODOS === "true";

// Site publicado (link da notificação no navegador).
const PROJETO = process.env.GCLOUD_PROJECT ||
  JSON.parse(process.env.FIREBASE_CONFIG || "{}").projectId;
const SITE = `https://${PROJETO}.web.app`;

// Só o que os alertas usam de users/{uid} (nada de CPF, e-mail ou nome).
const CAMPOS_ALERTA = ["fcmToken", "lastLocation", "alertsEnabled", "alertRadiusKm"];

initializeApp();

// Mesma região do banco Firestore (São Paulo).
setGlobalOptions({region: "southamerica-east1", maxInstances: 10});

exports.alertarProximos = onDocumentCreated("posts/{postId}", async (event) => {
  const post = event.data && event.data.data();
  if (!post || typeof post.latitude !== "number" ||
      typeof post.longitude !== "number") {
    return;
  }
  const postId = event.params.postId;
  const db = getFirestore();
  const agora = new Date();

  // 1) Candidatos. Modo de teste: todos os usuários. Normal: só quem tem a
  //    última localização a até 10 km (faixas de geohash, sem índice composto).
  const usuarios = new Map();
  if (ALERTAS_PARA_TODOS) {
    const snap = await db.collection("users").select(...CAMPOS_ALERTA).get();
    for (const doc of snap.docs) usuarios.set(doc.id, {uid: doc.id, ...doc.data()});
  } else {
    const faixas = geohashQueryBounds(
        [post.latitude, post.longitude], RAIO_MAXIMO_KM * 1000);
    const consultas = await Promise.all(faixas.map(([inicio, fim]) =>
      db.collection("users")
          .select(...CAMPOS_ALERTA)
          .orderBy("lastLocation.geohash")
          .startAt(inicio)
          .endAt(fim)
          .get()));
    for (const snap of consultas) {
      for (const doc of snap.docs) usuarios.set(doc.id, {uid: doc.id, ...doc.data()});
    }
  }

  // 2) Filtro: normal = distância <= raio de cada um, sem o autor e sem quem
  //    desligou os alertas; teste = todo mundo.
  const destinatarios = escolherDestinatarios(post, [...usuarios.values()],
      {paraTodos: ALERTAS_PARA_TODOS});
  if (destinatarios.length === 0) {
    logger.info(`Post ${postId}: ninguém para avisar.`);
    return;
  }

  // 3) Registro em users/{uid}/notifications (aparece no sino do app), com a
  //    mesma mensagem rica do push (e a distância de cada um, quando há).
  for (const lote of emLotes(destinatarios, 400)) {
    const batch = db.batch();
    for (const d of lote) {
      const {titulo, corpo, imagem} =
        montarMensagem(post, {distanciaKm: d.distanciaKm, agora});
      batch.set(db.collection("users").doc(d.uid).collection("notifications").doc(), {
        title: titulo,
        body: corpo,
        image: imagem,
        postId,
        type: post.type,
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // 4) Push (Android e navegador) para quem tem token, uma mensagem por
  //    pessoa; remove tokens que não servem mais.
  const comToken = destinatarios.filter((d) => d.token);
  let enviados = 0;
  for (const lote of emLotes(comToken, 500)) {
    const resposta = await getMessaging().sendEach(lote.map((d) => montarPush({
      token: d.token, postId, post, distanciaKm: d.distanciaKm, agora, site: SITE,
    })));
    enviados += resposta.successCount;
    const limpezas = [];
    resposta.responses.forEach((r, i) => {
      if (!r.success && r.error) {
        logger.warn(`Push para ${lote[i].uid.slice(0, 6)}… falhou: ${r.error.code}`);
        if (tokenInvalido(r.error.code)) {
          limpezas.push(db.collection("users").doc(lote[i].uid)
              .update({fcmToken: FieldValue.delete()}));
        }
      }
    });
    await Promise.all(limpezas);
  }

  logger.info(`Post ${postId}: ${destinatarios.length} avisados ` +
    `(${enviados} push enviados)${ALERTAS_PARA_TODOS ? " [modo teste: todos]" : ""}.`);
});

exports.analisarPet = onRequest({
  secrets: [GEMINI_API_KEY],
  // Só o site publicado e o app rodando local (Android não usa CORS).
  cors: [
    "https://petperdido-ff844.web.app",
    "https://petperdido-ff844.firebaseapp.com",
    /^http:\/\/localhost(:\d+)?$/,
  ],
  timeoutSeconds: 60,
  memory: "256MiB",
  maxInstances: 5,
}, async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({erro: "Use POST."});
    return;
  }

  // Só usuário logado no app (token do Firebase Auth).
  const cabecalho = req.get("Authorization") || "";
  const token = cabecalho.startsWith("Bearer ") ? cabecalho.slice(7) : "";
  let uid;
  try {
    uid = (await getAuth().verifyIdToken(token)).uid;
  } catch (_) {
    res.status(401).json({erro: "Entre na sua conta."});
    return;
  }

  const erroEntrada = validarEntrada(req.body);
  if (erroEntrada) {
    res.status(400).json({erro: erroEntrada});
    return;
  }

  const corpo = JSON.stringify(montarRequisicao(req.body));
  let ultimoStatus = 502;
  for (const modelo of MODELOS) {
    let resposta;
    try {
      resposta = await fetch(
          "https://generativelanguage.googleapis.com/v1beta/models/" +
          `${modelo}:generateContent`, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "x-goog-api-key": GEMINI_API_KEY.value(),
            },
            body: corpo,
          });
    } catch (e) {
      logger.error(`analisarPet: falha de rede com ${modelo}: ${e}`);
      ultimoStatus = 502;
      break;
    }

    if (resposta.ok) {
      const texto = extrairTexto(await resposta.json());
      if (!texto) {
        res.status(502).json({erro: "Resposta vazia da IA."});
        return;
      }
      logger.info(`analisarPet: ok (${modelo}, uid ${uid.slice(0, 6)}…).`);
      res.json({texto, modelo});
      return;
    }

    ultimoStatus = resposta.status;
    const detalhe = (await resposta.text()).slice(0, 300);
    logger.warn(`analisarPet: ${modelo} respondeu ${resposta.status}: ${detalhe}`);
    if (!tentarProximoModelo(resposta.status)) break;
  }

  // 429 = todos os modelos no limite do nível gratuito.
  res.status(ultimoStatus === 429 ? 429 : 502)
      .json({erro: ultimoStatus === 429 ? "Limite da IA atingido." : "IA indisponível."});
});

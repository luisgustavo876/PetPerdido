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

  // 1) Candidatos: usuários cuja última localização está a até 10 km
  //    (consulta por faixas de geohash, sem índice composto).
  const faixas = geohashQueryBounds(
      [post.latitude, post.longitude], RAIO_MAXIMO_KM * 1000);
  const consultas = await Promise.all(faixas.map(([inicio, fim]) =>
    db.collection("users")
        .orderBy("lastLocation.geohash")
        .startAt(inicio)
        .endAt(fim)
        .get()));
  const porUid = new Map();
  for (const snap of consultas) {
    for (const doc of snap.docs) porUid.set(doc.id, {uid: doc.id, ...doc.data()});
  }

  // 2) Filtro exato: distância <= raio de cada um, sem o autor e sem quem
  //    desligou os alertas.
  const destinatarios = escolherDestinatarios(post, [...porUid.values()]);
  if (destinatarios.length === 0) {
    logger.info(`Post ${postId}: ninguém por perto para avisar.`);
    return;
  }

  const {titulo, corpo} = montarMensagem(post);

  // 3) Registro em users/{uid}/notifications (aparece no sino do app).
  for (const lote of emLotes(destinatarios, 400)) {
    const batch = db.batch();
    for (const d of lote) {
      batch.set(db.collection("users").doc(d.uid).collection("notifications").doc(), {
        title: titulo,
        body: corpo,
        postId,
        type: post.type,
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // 4) Push para quem tem token; remove tokens que não servem mais.
  const comToken = destinatarios.filter((d) => d.token);
  let enviados = 0;
  for (const lote of emLotes(comToken, 500)) {
    const resposta = await getMessaging().sendEachForMulticast({
      tokens: lote.map((d) => d.token),
      notification: {title: titulo, body: corpo},
      data: {postId, type: String(post.type)},
      android: {priority: "high", notification: {channelId: "alertas_pets"}},
    });
    enviados += resposta.successCount;
    const limpezas = [];
    resposta.responses.forEach((r, i) => {
      if (!r.success && r.error && tokenInvalido(r.error.code)) {
        limpezas.push(db.collection("users").doc(lote[i].uid)
            .update({fcmToken: FieldValue.delete()}));
      }
    });
    await Promise.all(limpezas);
  }

  logger.info(`Post ${postId}: ${destinatarios.length} avisados ` +
    `(${enviados} push enviados).`);
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

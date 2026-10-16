/**
 * Cloud Functions do PetPerdido.
 *
 * alertarProximos: quando um post é criado, avisa (push FCM + registro em
 * users/{uid}/notifications) quem está perto, conforme o raio de cada um.
 */
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {setGlobalOptions} = require("firebase-functions/v2");
const logger = require("firebase-functions/logger");
const {initializeApp} = require("firebase-admin/app");
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

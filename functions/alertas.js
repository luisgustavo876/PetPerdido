/**
 * Lógica pura dos alertas por proximidade (sem Firebase), testável com
 * `npm test`. Usada pelo gatilho em index.js.
 */

/** Maior raio que um usuário pode escolher (km). A busca usa este raio. */
const RAIO_MAXIMO_KM = 10;

/** Raios oferecidos no app (km) e o padrão. */
const RAIOS_PERMITIDOS = [1, 3, 5, 10];
const RAIO_PADRAO_KM = 3;

const TITULOS = {
  perdi: "Pet perdido perto de você",
  achei: "Pet encontrado perto de você",
  avistei: "Pet avistado perto de você",
};

/** Distância em linha reta entre dois pontos, em km (Haversine). */
function distanciaKm(lat1, lng1, lat2, lng2) {
  const rad = (g) => (g * Math.PI) / 180;
  const dLat = rad(lat2 - lat1);
  const dLng = rad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * 6371 * Math.asin(Math.sqrt(a));
}

/** Raio do usuário; valores inválidos viram o padrão (3 km). */
function raioDoUsuario(usuario) {
  const raio = Number(usuario.alertRadiusKm);
  return RAIOS_PERMITIDOS.includes(raio) ? raio : RAIO_PADRAO_KM;
}

/**
 * Quem deve ser avisado sobre o post.
 * Exclui o autor, quem desligou os alertas (alertsEnabled === false), quem
 * não tem localização e quem está além do próprio raio.
 * @return {Array<{uid: string, token: (string|null), distanciaKm: number}>}
 */
function escolherDestinatarios(post, usuarios) {
  const saida = [];
  for (const u of usuarios) {
    if (u.uid === post.userId) continue;
    if (u.alertsEnabled === false) continue;
    const loc = u.lastLocation;
    if (!loc || typeof loc.lat !== "number" || typeof loc.lng !== "number") {
      continue;
    }
    const km = distanciaKm(post.latitude, post.longitude, loc.lat, loc.lng);
    if (km > raioDoUsuario(u)) continue;
    saida.push({
      uid: u.uid,
      token: typeof u.fcmToken === "string" && u.fcmToken ? u.fcmToken : null,
      distanciaKm: km,
    });
  }
  return saida;
}

/**
 * Título e corpo da notificação: tipo no título; espécie, cor e bairro no
 * corpo. Ex.: "Cão caramelo e branco · Vila Barth, Itapetininga".
 */
function montarMensagem(post) {
  const titulo = TITULOS[post.type] || "Pet perto de você";
  const cores = Array.isArray(post.colors) ?
    post.colors.map((c) => String(c).toLowerCase()) :
    [];
  const especie = post.species || "Pet";
  const descricao = cores.length ?
    `${especie} ${cores.join(" e ")}` :
    especie;
  const bairro = post.lastSeenAddress || "sua região";
  return {titulo, corpo: `${descricao} · ${bairro}`};
}

/** Erros do FCM que indicam token que não serve mais (deve ser apagado). */
function tokenInvalido(codigoErro) {
  return [
    "messaging/registration-token-not-registered",
    "messaging/invalid-registration-token",
    "messaging/invalid-argument",
  ].includes(codigoErro);
}

/** Divide uma lista em pedaços de até [tamanho] itens. */
function emLotes(lista, tamanho) {
  const lotes = [];
  for (let i = 0; i < lista.length; i += tamanho) {
    lotes.push(lista.slice(i, i + tamanho));
  }
  return lotes;
}

module.exports = {
  RAIO_MAXIMO_KM,
  RAIOS_PERMITIDOS,
  RAIO_PADRAO_KM,
  distanciaKm,
  raioDoUsuario,
  escolherDestinatarios,
  montarMensagem,
  tokenInvalido,
  emLotes,
};

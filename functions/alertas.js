/**
 * Lógica pura dos alertas por proximidade (sem Firebase), testável com
 * `npm test`. Usada pelo gatilho em index.js.
 */

/** Maior raio que um usuário pode escolher (km). A busca usa este raio. */
const RAIO_MAXIMO_KM = 10;

/** Raios oferecidos no app (km) e o padrão. */
const RAIOS_PERMITIDOS = [1, 3, 5, 10];
const RAIO_PADRAO_KM = 3;

/** Como cada tipo aparece na notificação. */
const TIPOS = {
  perdi: {emoji: "🚨", rotulo: "PERDIDO", quando: "sumiu"},
  achei: {emoji: "🏠", rotulo: "ENCONTRADO", quando: "encontrado"},
  avistei: {emoji: "👀", rotulo: "AVISTADO", quando: "visto"},
};

/** Raças que não ajudam a reconhecer o pet (ficam fora da notificação). */
const RACAS_GENERICAS = ["sem raça definida", "desconhecida", ""];

/** Tamanho máximo do trecho da descrição na notificação. */
const MAX_TRECHO = 100;

/** Fuso das datas mostradas (o servidor roda em UTC). */
const FUSO = "America/Sao_Paulo";

/** Vermelho do app (AppColors.primary), usado na notificação do Android. */
const COR_APP = "#E53935";

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
 *
 * Normal: exclui o autor, quem desligou os alertas (alertsEnabled === false),
 * quem não tem localização e quem está além do próprio raio.
 * Com [paraTodos] (modo de teste): todos os usuários, inclusive o autor e
 * quem está longe; a distância vem quando o usuário tem localização.
 * @return {Array<{uid: string, token: (string|null),
 *   distanciaKm: (number|null)}>}
 */
function escolherDestinatarios(post, usuarios, {paraTodos = false} = {}) {
  const saida = [];
  for (const u of usuarios) {
    const token = typeof u.fcmToken === "string" && u.fcmToken ?
      u.fcmToken : null;
    const loc = u.lastLocation;
    const temLocal = !!loc && typeof loc.lat === "number" &&
      typeof loc.lng === "number";
    const km = temLocal ?
      distanciaKm(post.latitude, post.longitude, loc.lat, loc.lng) :
      null;

    if (paraTodos) {
      saida.push({uid: u.uid, token, distanciaKm: km});
      continue;
    }
    if (u.uid === post.userId) continue;
    if (u.alertsEnabled === false) continue;
    if (km === null || km > raioDoUsuario(u)) continue;
    saida.push({uid: u.uid, token, distanciaKm: km});
  }
  return saida;
}

/** Date a partir de Timestamp do Firestore, Date ou texto ISO (ou null). */
function paraData(valor) {
  if (!valor) return null;
  if (valor instanceof Date) return isNaN(valor) ? null : valor;
  if (typeof valor.toDate === "function") return valor.toDate();
  if (typeof valor === "string") {
    const d = new Date(valor);
    return isNaN(d) ? null : d;
  }
  return null;
}

/** Dia (aaaa-mm-dd), "dd/mm" e "hh:mm" de uma data no fuso de Brasília. */
function partesNoFuso(data) {
  const f = new Intl.DateTimeFormat("pt-BR", {
    timeZone: FUSO, year: "numeric", month: "2-digit", day: "2-digit",
    hour: "2-digit", minute: "2-digit", hourCycle: "h23",
  });
  const p = Object.fromEntries(f.formatToParts(data).map((x) => [x.type, x.value]));
  return {
    dia: `${p.year}-${p.month}-${p.day}`,
    ddmm: `${p.day}/${p.month}`,
    hora: `${p.hour}:${p.minute}`,
  };
}

/** "hoje às 09:00", "ontem às 18:30" ou "12/10 às 14:00" (Brasília). */
function quandoTexto(data, agora) {
  if (!data) return null;
  const d = partesNoFuso(data);
  if (d.dia === partesNoFuso(agora).dia) return `hoje às ${d.hora}`;
  const ontem = new Date(agora.getTime() - 24 * 60 * 60 * 1000);
  if (d.dia === partesNoFuso(ontem).dia) return `ontem às ${d.hora}`;
  return `${d.ddmm} às ${d.hora}`;
}

/** "a ~300 m de você" ou "a 1,2 km de você" (coordenadas são de ~100 m). */
function distanciaTexto(km) {
  if (typeof km !== "number" || !isFinite(km)) return null;
  if (km < 1) return `a ~${Math.max(100, Math.round(km * 10) * 100)} m de você`;
  const valor = km < 10 ? km.toFixed(1).replace(".", ",") : String(Math.round(km));
  return `a ${valor} km de você`;
}

/** Começo da descrição, cortado numa palavra, com reticências. */
function trecho(texto, max = MAX_TRECHO) {
  const limpo = String(texto || "").replace(/\s+/g, " ").trim();
  if (limpo.length <= max) return limpo;
  const corte = limpo.slice(0, max);
  const espaco = corte.lastIndexOf(" ");
  return `${(espaco > max / 2 ? corte.slice(0, espaco) : corte).replace(/[\s,.;:]+$/, "")}…`;
}

/**
 * Conteúdo da notificação, pensado para dar para saber se a pessoa pode
 * ajudar sem abrir o app: tipo, nome, espécie e cor no título; onde, quando
 * e a que distância; porte, raça e características; começo da descrição; e
 * a foto. Só dados públicos do post (nada de autor, e-mail ou coordenadas).
 * @return {{titulo: string, corpo: string, imagem: (string|null)}}
 */
function montarMensagem(post, {distanciaKm: km = null, agora = new Date()} = {}) {
  const tipo = TIPOS[post.type] || {emoji: "🐾", rotulo: "PET", quando: "visto"};
  const especie = String(post.species || "pet").toLowerCase();
  const cores = Array.isArray(post.colors) ?
    post.colors.map((c) => String(c).toLowerCase()).join(" e ") :
    "";
  const oQue = [especie, cores].filter(Boolean).join(" ");
  const nome = post.type === "perdi" && post.petName &&
    post.petName !== "Sem nome" ? post.petName : null;
  const titulo = `${tipo.emoji} ${tipo.rotulo}: ${nome ? `${nome} · ` : ""}${oQue}`;

  const quando = quandoTexto(paraData(post.eventAt) || paraData(post.createdAt),
      agora);
  const linhaOnde = [
    `📍 ${post.lastSeenAddress || "local não informado"}`,
    quando ? `${tipo.quando} ${quando}` : null,
    distanciaTexto(km),
  ].filter(Boolean).join(" · ");

  const raca = RACAS_GENERICAS.includes(String(post.breed || "").toLowerCase()) ?
    null : post.breed;
  const caracteristicas = Array.isArray(post.traits) ? post.traits.slice(0, 3) : [];
  const linhaPet = [post.size, raca, ...caracteristicas].filter(Boolean).join(" · ");

  const descricao = trecho(post.description);
  const corpo = [linhaOnde, linhaPet, descricao ? `“${descricao}”` : null]
      .filter(Boolean).join("\n");

  const imagem = typeof post.photoUrl === "string" &&
    post.photoUrl.startsWith("https://") ? post.photoUrl : null;
  return {titulo, corpo, imagem};
}

/**
 * Mensagem do FCM para um destinatário (Android e navegador), com a foto e
 * o link que abre o post no site.
 */
function montarPush({token, postId, post, distanciaKm: km = null,
  agora = new Date(), site}) {
  const {titulo, corpo, imagem} = montarMensagem(post, {distanciaKm: km, agora});
  // Pet perdido é urgente: vibra mais e fica na tela até a pessoa tocar.
  const urgente = post.type === "perdi";
  return {
    token,
    notification: {title: titulo, body: corpo, ...(imagem ? {imageUrl: imagem} : {})},
    data: {postId, type: String(post.type), ...(imagem ? {imagem} : {})},
    // App Android: pata branca na barra de status, vermelho do app, som e
    // conteúdo visível na tela bloqueada (só dados públicos do post).
    android: {
      priority: "high",
      notification: {
        channelId: "alertas_pets",
        tag: postId,
        icon: "ic_notification",
        color: COR_APP,
        defaultSound: true,
        visibility: "public",
        priority: "high",
      },
    },
    // Navegador (Chrome/Edge/Firefox): foto grande, ícone do app, selo da
    // pata, botões e vibração. A mesma notificação é trocada, não repetida.
    webpush: {
      headers: {Urgency: "high", TTL: String(24 * 60 * 60)},
      notification: {
        title: titulo,
        body: corpo,
        lang: "pt-BR",
        icon: `${site}/icons/Icon-192.png`,
        badge: `${site}/icons/badge-96.png`,
        ...(imagem ? {image: imagem} : {}),
        tag: postId,
        renotify: true,
        requireInteraction: urgente,
        vibrate: urgente ? [300, 120, 300, 120, 300] : [200, 100, 200],
        actions: [
          {action: "ver", title: "Ver o pet"},
          {action: "mapa", title: "Ver no mapa"},
        ],
      },
      fcmOptions: {link: `${site}/?post=${encodeURIComponent(postId)}`},
    },
  };
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
  paraData,
  quandoTexto,
  distanciaTexto,
  trecho,
  montarMensagem,
  montarPush,
  tokenInvalido,
  emLotes,
};

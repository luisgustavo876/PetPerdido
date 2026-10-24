// Testes da lógica pura dos alertas: `npm test` (node:test, sem dependências).
const test = require("node:test");
const assert = require("node:assert/strict");
const {
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
} = require("../alertas");

// 16/10/2026 12:00 em Brasília (15:00 UTC).
const AGORA = new Date("2026-10-16T15:00:00Z");

const post = {
  userId: "autor",
  type: "perdi",
  petName: "Pipoca",
  species: "Cão",
  breed: "Labrador",
  size: "Médio",
  colors: ["Caramelo", "Branco"],
  traits: ["Com coleira", "Dócil", "Ferido", "Castrado"],
  description: "Cachorro dócil de coleira azul, atende por Pipoca e tem medo de fogos.",
  lastSeenAddress: "Vila Barth, Itapetininga",
  latitude: -23.59,
  longitude: -48.053,
  eventAt: new Date("2026-10-16T12:00:00Z"), // 09:00 em Brasília
  photoUrl: "https://firebasestorage.googleapis.com/v0/b/x/o/posts%2Fp1%2Ffoto.jpg?alt=media",
};

const usuario = (uid, lat, lng, extra = {}) => ({
  uid,
  alertsEnabled: true,
  alertRadiusKm: 3,
  fcmToken: `token-${uid}`,
  lastLocation: {lat, lng},
  ...extra,
});

test("distanciaKm: 1 grau de latitude ≈ 111,2 km e mesmo ponto = 0", () => {
  assert.ok(Math.abs(distanciaKm(0, 0, 1, 0) - 111.19) < 0.05);
  assert.equal(distanciaKm(-23.59, -48.05, -23.59, -48.05), 0);
});

test("raioDoUsuario: só 1, 3, 5 ou 10 km; resto vira 3", () => {
  assert.equal(raioDoUsuario({alertRadiusKm: 10}), 10);
  assert.equal(raioDoUsuario({alertRadiusKm: 7}), 3);
  assert.equal(raioDoUsuario({}), 3);
});

test("escolherDestinatarios: perto entra, longe não", () => {
  const perto = usuario("perto", -23.595, -48.053); // ~0,6 km
  const longe = usuario("longe", -23.70, -48.053); // ~12 km
  const r = escolherDestinatarios(post, [perto, longe]);
  assert.deepEqual(r.map((d) => d.uid), ["perto"]);
  assert.equal(r[0].token, "token-perto");
});

test("escolherDestinatarios: respeita o raio de cada usuário", () => {
  // ~4,4 km: fora de 3 km, dentro de 5 km
  const raio3 = usuario("r3", -23.55, -48.053);
  const raio5 = usuario("r5", -23.55, -48.053, {alertRadiusKm: 5});
  const r = escolherDestinatarios(post, [raio3, raio5]);
  assert.deepEqual(r.map((d) => d.uid), ["r5"]);
});

test("escolherDestinatarios: exclui autor, desligados e sem localização", () => {
  const autor = usuario("autor", -23.59, -48.053);
  const desligado = usuario("off", -23.59, -48.053, {alertsEnabled: false});
  const semLocal = usuario("semLocal", 0, 0, {lastLocation: undefined});
  const r = escolherDestinatarios(post, [autor, desligado, semLocal]);
  assert.equal(r.length, 0);
});

test("escolherDestinatarios: sem token ainda recebe o registro (token null)", () => {
  const semToken = usuario("semToken", -23.59, -48.053, {fcmToken: undefined});
  const r = escolherDestinatarios(post, [semToken]);
  assert.equal(r.length, 1);
  assert.equal(r[0].token, null);
});

test("escolherDestinatarios (modo teste): todos, inclusive autor e longe", () => {
  const usuarios = [
    usuario("autor", -23.59, -48.053),
    usuario("longe", -23.70, -48.053),
    usuario("off", -23.59, -48.053, {alertsEnabled: false}),
    usuario("semLocal", 0, 0, {lastLocation: undefined, fcmToken: undefined}),
  ];
  const r = escolherDestinatarios(post, usuarios, {paraTodos: true});
  assert.deepEqual(r.map((d) => d.uid), ["autor", "longe", "off", "semLocal"]);
  assert.equal(r[0].distanciaKm, 0);
  assert.ok(r[1].distanciaKm > 10);
  assert.equal(r[3].distanciaKm, null);
  assert.equal(r[3].token, null);
});

test("paraData: Timestamp, Date, texto e inválidos", () => {
  const d = new Date("2026-10-16T12:00:00Z");
  assert.equal(paraData({toDate: () => d}), d);
  assert.equal(paraData(d), d);
  assert.equal(paraData("2026-10-16T12:00:00Z").getTime(), d.getTime());
  assert.equal(paraData("ontem"), null);
  assert.equal(paraData(undefined), null);
});

test("quandoTexto: hoje, ontem ou data, no horário de Brasília", () => {
  assert.equal(quandoTexto(new Date("2026-10-16T12:00:00Z"), AGORA), "hoje às 09:00");
  assert.equal(quandoTexto(new Date("2026-10-15T21:30:00Z"), AGORA), "ontem às 18:30");
  // 02:30 UTC do dia 16 ainda é dia 15 em Brasília (23:30): "ontem".
  assert.equal(quandoTexto(new Date("2026-10-16T02:30:00Z"), AGORA), "ontem às 23:30");
  assert.equal(quandoTexto(new Date("2026-10-12T17:00:00Z"), AGORA), "12/10 às 14:00");
  assert.equal(quandoTexto(null, AGORA), null);
});

test("distanciaTexto: metros arredondados, km com vírgula", () => {
  assert.equal(distanciaTexto(0.34), "a ~300 m de você");
  assert.equal(distanciaTexto(0.02), "a ~100 m de você");
  assert.equal(distanciaTexto(1.24), "a 1,2 km de você");
  assert.equal(distanciaTexto(12.6), "a 13 km de você");
  assert.equal(distanciaTexto(null), null);
});

test("trecho: corta na palavra e põe reticências", () => {
  assert.equal(trecho("  curto   demais "), "curto demais");
  const longo = "palavra ".repeat(30);
  const t = trecho(longo, 40);
  assert.ok(t.length <= 41);
  assert.ok(t.endsWith("palavra…"));
  assert.equal(trecho(undefined), "");
});

test("montarMensagem: título, onde/quando/distância, pet, descrição e foto", () => {
  const m = montarMensagem(post, {distanciaKm: 1.24, agora: AGORA});
  assert.equal(m.titulo, "🚨 PERDIDO: Pipoca · cão caramelo e branco");
  const [onde, pet, descricao] = m.corpo.split("\n");
  assert.equal(onde, "📍 Vila Barth, Itapetininga · sumiu hoje às 09:00 · a 1,2 km de você");
  assert.equal(pet, "Médio · Labrador · Com coleira · Dócil · Ferido");
  assert.equal(descricao,
      "“Cachorro dócil de coleira azul, atende por Pipoca e tem medo de fogos.”");
  assert.equal(m.imagem, post.photoUrl);
});

test("montarMensagem: achei/avistei sem nome, raça genérica e sem foto", () => {
  const achei = montarMensagem({...post, type: "achei", breed: "Sem raça definida",
    photoUrl: null, traits: []}, {agora: AGORA});
  assert.equal(achei.titulo, "🏠 ENCONTRADO: cão caramelo e branco");
  assert.equal(achei.corpo.split("\n")[0],
      "📍 Vila Barth, Itapetininga · encontrado hoje às 09:00");
  assert.equal(achei.corpo.split("\n")[1], "Médio");
  assert.equal(achei.imagem, null);
  const avistei = montarMensagem({...post, type: "avistei", colors: undefined},
      {agora: AGORA});
  assert.equal(avistei.titulo, "👀 AVISTADO: cão");
  assert.ok(avistei.corpo.includes("visto hoje às 09:00"));
});

test("montarMensagem: post antigo sem data, descrição nem bairro", () => {
  const m = montarMensagem({type: "perdi", species: "Gato"}, {agora: AGORA});
  assert.equal(m.titulo, "🚨 PERDIDO: gato");
  assert.equal(m.corpo, "📍 local não informado");
});

test("montarPush: foto no Android e no navegador, link do post e dados", () => {
  const p = montarPush({token: "t1", postId: "p 1", post, distanciaKm: 0.5,
    agora: AGORA, site: "https://petperdido-ff844.web.app"});
  assert.equal(p.token, "t1");
  assert.equal(p.notification.imageUrl, post.photoUrl);
  assert.equal(p.webpush.notification.image, post.photoUrl);
  assert.equal(p.webpush.fcmOptions.link, "https://petperdido-ff844.web.app/?post=p%201");
  assert.equal(p.android.notification.channelId, "alertas_pets");
  assert.deepEqual(p.data, {postId: "p 1", type: "perdi", imagem: post.photoUrl});
  const semFoto = montarPush({token: "t2", postId: "p2", post: {...post, photoUrl: ""},
    agora: AGORA, site: "https://x.web.app"});
  assert.equal(semFoto.notification.imageUrl, undefined);
  assert.equal(semFoto.webpush.notification.image, undefined);
  assert.equal(semFoto.data.imagem, undefined);
});

test("tokenInvalido e emLotes", () => {
  assert.ok(tokenInvalido("messaging/registration-token-not-registered"));
  assert.ok(!tokenInvalido("messaging/internal-error"));
  assert.deepEqual(emLotes([1, 2, 3, 4, 5], 2), [[1, 2], [3, 4], [5]]);
});

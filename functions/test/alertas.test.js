// Testes da lógica pura dos alertas: `npm test` (node:test, sem dependências).
const test = require("node:test");
const assert = require("node:assert/strict");
const {
  distanciaKm,
  raioDoUsuario,
  escolherDestinatarios,
  montarMensagem,
  tokenInvalido,
  emLotes,
} = require("../alertas");

const post = {
  userId: "autor",
  type: "perdi",
  species: "Cão",
  colors: ["Caramelo", "Branco"],
  lastSeenAddress: "Vila Barth, Itapetininga",
  latitude: -23.59,
  longitude: -48.053,
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

test("montarMensagem: título pelo tipo e corpo com espécie, cor e bairro", () => {
  assert.deepEqual(montarMensagem(post), {
    titulo: "Pet perdido perto de você",
    corpo: "Cão caramelo e branco · Vila Barth, Itapetininga",
  });
  assert.equal(montarMensagem({...post, type: "achei"}).titulo,
      "Pet encontrado perto de você");
  assert.equal(montarMensagem({...post, type: "avistei"}).titulo,
      "Pet avistado perto de você");
});

test("montarMensagem: post antigo sem cores", () => {
  const {corpo} = montarMensagem({...post, colors: undefined});
  assert.equal(corpo, "Cão · Vila Barth, Itapetininga");
});

test("tokenInvalido e emLotes", () => {
  assert.ok(tokenInvalido("messaging/registration-token-not-registered"));
  assert.ok(!tokenInvalido("messaging/internal-error"));
  assert.deepEqual(emLotes([1, 2, 3, 4, 5], 2), [[1, 2], [3, 4], [5]]);
});

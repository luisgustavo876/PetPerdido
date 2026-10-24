const {test} = require("node:test");
const assert = require("node:assert/strict");
const {
  MODELOS,
  validarEntrada,
  montarEsquema,
  montarRequisicao,
  extrairTexto,
  tentarProximoModelo,
} = require("../ia");

const opcoes = {
  especies: ["Cão", "Gato"],
  portes: ["Pequeno", "Médio", "Grande"],
  cores: ["Preto", "Branco", "Caramelo"],
  caracteristicas: ["Dócil", "Com coleira"],
};

test("aceita foto ou descrição, nunca as duas nem nenhuma", () => {
  assert.equal(validarEntrada({imagem: "QUJD", opcoes}), null);
  assert.equal(validarEntrada({descricao: "Cachorro caramelo de coleira", opcoes}), null);
  assert.match(validarEntrada({opcoes}), /foto ou uma descrição/);
  assert.match(validarEntrada({imagem: "QUJD", descricao: "Cachorro caramelo", opcoes}),
      /foto ou uma descrição/);
  assert.match(validarEntrada(null), /vazio/);
});

test("barra foto grande, base64 inválido e tipo não aceito", () => {
  assert.match(validarEntrada({imagem: "A".repeat(1500001), opcoes}), /grande/);
  assert.match(validarEntrada({imagem: "não é base64!", opcoes}), /inválida/);
  assert.match(validarEntrada({imagem: "QUJD", mime: "application/pdf", opcoes}), /Tipo/);
});

test("descrição de 10 a 1000 caracteres", () => {
  assert.match(validarEntrada({descricao: "  curta  ", opcoes}), /curta/);
  assert.match(validarEntrada({descricao: "x".repeat(1001), opcoes}), /longa/);
});

test("opções obrigatórias e curtas", () => {
  assert.match(validarEntrada({imagem: "QUJD"}), /Opções/);
  assert.match(validarEntrada({imagem: "QUJD", opcoes: {...opcoes, cores: []}}), /Opções/);
  assert.match(validarEntrada({imagem: "QUJD",
    opcoes: {...opcoes, portes: ["x".repeat(41)]}}), /Opções/);
});

test("esquema usa só os valores do app (+ Indefinido na espécie)", () => {
  const e = montarEsquema(opcoes);
  assert.deepEqual(e.properties.species.enum, ["Cão", "Gato", "Indefinido"]);
  assert.deepEqual(e.properties.colors.items.enum, opcoes.cores);
  assert.deepEqual(e.properties.traits.items.enum, opcoes.caracteristicas);
});

test("requisição com foto manda a imagem; com texto, só o texto", () => {
  const comFoto = montarRequisicao({imagem: "QUJD", opcoes});
  assert.equal(comFoto.contents[0].parts[1].inlineData.data, "QUJD");
  assert.equal(comFoto.contents[0].parts[1].inlineData.mimeType, "image/jpeg");
  assert.equal(comFoto.generationConfig.responseMimeType, "application/json");
  const comTexto = montarRequisicao({descricao: " Gato preto ", opcoes});
  assert.equal(comTexto.contents[0].parts.length, 1);
  assert.match(comTexto.contents[0].parts[0].text, /"Gato preto"/);
});

test("extrai o texto da resposta e ignora o raciocínio", () => {
  const r = {candidates: [{content: {parts: [
    {text: "pensando...", thought: true}, {text: "{\"species\":"}, {text: "\"Cão\"}"}]}}]};
  assert.equal(extrairTexto(r), "{\"species\":\"Cão\"}");
  assert.equal(extrairTexto({}), null);
  assert.equal(extrairTexto({candidates: [{content: {parts: []}}]}), null);
});

test("troca de modelo só em limite (429) ou modelo inexistente (404)", () => {
  assert.ok(MODELOS.length >= 2);
  assert.equal(tentarProximoModelo(429), true);
  assert.equal(tentarProximoModelo(404), true);
  assert.equal(tentarProximoModelo(400), false);
  assert.equal(tentarProximoModelo(500), false);
});

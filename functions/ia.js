/**
 * Lógica pura da IA (análise de foto/descrição do pet com o Gemini).
 * Sem acesso à rede nem ao Firebase: fácil de testar.
 */

// Modelos tentados em ordem. No nível gratuito cada modelo tem a sua cota:
// se um responder 429 (limite) ou 404 (não existe), tenta o próximo.
const MODELOS = [
  "gemini-3.6-flash",
  "gemini-3.8-flash",
  "gemini-3.5-flash-lite",
  "gemini-2.5-flash",
];

const INSTRUCOES = `Você ajuda um app de pets perdidos a descrever animais.
Analise somente o animal principal (cão ou gato). Ignore pessoas, roupas,
placas, textos e o fundo. Nunca descreva pessoas.
Se não houver cão nem gato, responda species "Indefinido" e deixe as listas vazias.
Use apenas os valores permitidos no esquema. Para cores, escolha no máximo 2
das opções. Para a raça, um nome curto em português ou "Sem raça definida"
se for mestiço ou incerto. Para características, só as que forem visíveis
(ou citadas, no caso de texto).`;

// Limites da entrada (a foto chega reduzida pelo app: ~1024 px, JPEG).
const MAX_FOTO_BASE64 = 1500000; // ~1,1 MB de imagem
const MIN_DESCRICAO = 10;
const MAX_DESCRICAO = 1000;
const MAX_OPCOES = 60;
const MAX_TAMANHO_OPCAO = 40;
const TIPOS_IMAGEM = ["image/jpeg", "image/png", "image/webp"];

/** Lista de textos curtos (as opções do app). */
function listaValida(lista) {
  return Array.isArray(lista) && lista.length > 0 &&
    lista.length <= MAX_OPCOES &&
    lista.every((x) => typeof x === "string" && x.length > 0 &&
      x.length <= MAX_TAMANHO_OPCAO);
}

/**
 * Confere o corpo do pedido. Retorna a mensagem de erro, ou null se ok.
 * Formato: {imagem?: base64, mime?: string, descricao?: string,
 *           opcoes: {especies, portes, cores, caracteristicas}}
 */
function validarEntrada(corpo) {
  if (!corpo || typeof corpo !== "object") return "Pedido vazio.";
  const temImagem = typeof corpo.imagem === "string" && corpo.imagem.length > 0;
  const temDescricao = typeof corpo.descricao === "string";
  if (temImagem === temDescricao) return "Envie uma foto ou uma descrição.";
  if (temImagem) {
    if (corpo.imagem.length > MAX_FOTO_BASE64) return "Foto muito grande.";
    if (!/^[A-Za-z0-9+/=]+$/.test(corpo.imagem)) return "Foto inválida.";
    if (!TIPOS_IMAGEM.includes(corpo.mime || "image/jpeg")) {
      return "Tipo de imagem não aceito.";
    }
  } else {
    const t = corpo.descricao.trim().length;
    if (t < MIN_DESCRICAO) return "Descrição muito curta.";
    if (t > MAX_DESCRICAO) return "Descrição muito longa.";
  }
  const o = corpo.opcoes;
  if (!o || !["especies", "portes", "cores", "caracteristicas"]
      .every((k) => listaValida(o[k]))) {
    return "Opções inválidas.";
  }
  return null;
}

/** Esquema da resposta (só valores das listas do app). */
function montarEsquema(opcoes) {
  const texto = (valores) => ({type: "STRING", enum: valores});
  return {
    type: "OBJECT",
    properties: {
      species: texto([...opcoes.especies, "Indefinido"]),
      size: texto(opcoes.portes),
      colors: {type: "ARRAY", items: texto(opcoes.cores),
        description: "No máximo 2 cores."},
      breed: {type: "STRING", description: "Raça curta ou \"Sem raça definida\"."},
      traits: {type: "ARRAY", items: texto(opcoes.caracteristicas)},
    },
  };
}

/** Corpo do generateContent da API do Gemini. */
function montarRequisicao(corpo) {
  const partes = corpo.imagem ?
    [{text: "Descreva o pet desta foto."},
      {inlineData: {mimeType: corpo.mime || "image/jpeg", data: corpo.imagem}}] :
    [{text: "Extraia os dados do pet a partir desta descrição: " +
      JSON.stringify(corpo.descricao.trim())}];
  return {
    systemInstruction: {parts: [{text: INSTRUCOES}]},
    contents: [{role: "user", parts: partes}],
    generationConfig: {
      responseMimeType: "application/json",
      responseSchema: montarEsquema(corpo.opcoes),
      temperature: 0.2,
    },
  };
}

/** Texto (JSON) da primeira resposta do Gemini, ou null. */
function extrairTexto(resposta) {
  const partes = resposta && resposta.candidates && resposta.candidates[0] &&
    resposta.candidates[0].content && resposta.candidates[0].content.parts;
  if (!Array.isArray(partes)) return null;
  const texto = partes.filter((p) => typeof p.text === "string" && !p.thought)
      .map((p) => p.text).join("");
  return texto || null;
}

/** Vale tentar o próximo modelo? (limite do modelo ou modelo inexistente) */
function tentarProximoModelo(status) {
  return status === 429 || status === 404;
}

module.exports = {
  MODELOS,
  validarEntrada,
  montarEsquema,
  montarRequisicao,
  extrairTexto,
  tentarProximoModelo,
};

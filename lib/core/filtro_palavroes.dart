import 'formatters.dart';

/// Filtro de palavrões do chat (função pura e testável).
///
/// Compara palavra por palavra, sem diferenciar maiúsculas nem acentos, e
/// troca cada palavrão por "***". Palavras ambíguas do dia a dia (ex.: "pau",
/// "rola", "pinto") ficam de fora para não censurar frases normais.
class FiltroPalavroes {
  FiltroPalavroes._();

  static const substituto = '***';

  /// Lista em minúsculas e sem acentos.
  static const _palavroes = {
    'porra', 'caralho', 'krl', 'crl', 'merda', 'bosta', 'cacete',
    'puta', 'puto', 'putaria', 'putinha', 'fdp', 'pqp', 'vsf', 'vtnc', 'tnc',
    'foda', 'fodase', 'foder', 'fodido', 'fodida', 'fudido', 'fudida',
    'buceta', 'boceta', 'xoxota', 'cu', 'cuzao', 'cusao',
    'arrombado', 'arrombada', 'desgraca', 'desgracado', 'desgracada',
    'vagabundo', 'vagabunda', 'vadia', 'piranha', 'corno', 'corna',
    'escroto', 'escrota', 'babaca', 'otario', 'otaria', 'imbecil', 'idiota',
    'retardado', 'retardada', 'viado', 'bicha', 'sapatao',
  };

  static final _palavra = RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ]+");

  /// Troca os palavrões de [texto] por "***", mantendo o resto igual.
  static String filtrar(String texto) {
    return texto.replaceAllMapped(_palavra, (m) {
      final palavra = m.group(0)!;
      return _palavroes.contains(Formatters.normalizar(palavra))
          ? substituto
          : palavra;
    });
  }

  /// O texto tem algum palavrão?
  static bool contemPalavrao(String texto) => filtrar(texto) != texto;
}

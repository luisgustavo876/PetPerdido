/// Funções de texto e formatação (puras e testáveis).
class Formatters {
  Formatters._();

  static const _comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  static const _semAcento = 'aaaaaeeeeiiiiooooouuuucn';

  /// Minúsculas e sem acentos — para comparar textos ("Câo" == "cao").
  static String normalizar(String texto) {
    final buffer = StringBuffer();
    for (final rune in texto.toLowerCase().runes) {
      final c = String.fromCharCode(rune);
      final i = _comAcento.indexOf(c);
      buffer.write(i >= 0 ? _semAcento[i] : c);
    }
    return buffer.toString();
  }

  /// "agora", "há 5 min", "há 2 h", "há 3 dias" ou "em 12/10/2026".
  static String tempoRelativo(DateTime data, DateTime agora) {
    final diff = agora.difference(data);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    if (diff.inDays == 1) return 'há 1 dia';
    if (diff.inDays < 30) return 'há ${diff.inDays} dias';
    String dois(int n) => n.toString().padLeft(2, '0');
    return 'em ${dois(data.day)}/${dois(data.month)}/${data.year}';
  }

  /// "a 350 m", "a 1,2 km" ou "a 15 km".
  static String distancia(double km) {
    if (km < 1) {
      final metros = (km * 1000 / 10).round() * 10; // de 10 em 10 m
      return 'a ${metros < 10 ? 10 : metros} m';
    }
    if (km < 10) return 'a ${km.toStringAsFixed(1).replaceAll('.', ',')} km';
    return 'a ${km.round()} km';
  }
}

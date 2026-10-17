import '../models/post_model.dart';

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

  /// Nome para exibir o usuário em qualquer tela. Nunca mostra e-mail:
  /// nome vazio ou com "@" (posts antigos gravaram o e-mail) vira "Usuário".
  static String nomeUsuario(String? nome) {
    final n = nome?.trim() ?? '';
    if (n.isEmpty || n.contains('@')) return 'Usuário';
    return n;
  }

  /// "29/06/2006" (padrão brasileiro).
  static String data(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year}';
  }

  /// Lê "29/06/2006" (ou "29062006"). Retorna null se estiver incompleta ou
  /// se o dia/mês não existir (ex.: 31/02/2006, 15/13/2006).
  static DateTime? lerData(String texto) {
    final digitos = texto.replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 8) return null;
    final dia = int.parse(digitos.substring(0, 2));
    final mes = int.parse(digitos.substring(2, 4));
    final ano = int.parse(digitos.substring(4));
    if (ano < 1900 || mes < 1 || mes > 12 || dia < 1) return null;
    final data = DateTime(ano, mes, dia);
    // DateTime "rola" datas inválidas (31/02 vira 03/03): confere de volta.
    if (data.day != dia || data.month != mes || data.year != ano) return null;
    return data;
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

  /// Texto do "Compartilhar": tipo, pet, descrição, bairro e o nome do app.
  /// Só dados públicos do post (nada de e-mail, CPF ou coordenadas).
  static String textoCompartilhar(PostModel post) {
    final nome = post.petName.isNotEmpty && post.petName != 'Sem nome'
        ? '${post.petName} — '
        : '';
    final caracteristicas = [
      post.species,
      if (post.breed.isNotEmpty) post.breed,
      ...post.colors,
    ].join(', ');
    return '${post.type.label.toUpperCase()}: $nome$caracteristicas\n'
        '${post.description}\n'
        'Região: ${post.lastSeenAddress}\n\n'
        'Viu este pet? Ajude pelo app PetPerdido.';
  }
}

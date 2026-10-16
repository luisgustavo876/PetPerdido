import '../models/post_model.dart';
import 'app_constants.dart';
import 'geo.dart';

/// Aviso de posts semelhantes: um "Perdi" pode corresponder a um "Achei" ou
/// "Avistei" (e vice-versa). Funções puras e testáveis.
class Similaridade {
  Similaridade._();

  /// Perdi é "oposto" de Achei e de Avistei; Achei e Avistei não se cruzam.
  static bool tiposOpostos(PostType a, PostType b) =>
      (a == PostType.lost) != (b == PostType.lost);

  /// 0 = não são semelhantes. Acima de 0, quanto maior, mais parecidos.
  ///
  /// Obrigatório: tipos opostos, mesma espécie, nenhum resolvido, até
  /// [AppConstants.similarMaxKm] km e até [AppConstants.similarWindowDays]
  /// dias entre os ocorridos. Além disso, precisa ter cor em comum ou o
  /// mesmo porte (e, se os dois informaram cores, ao menos uma em comum).
  static double similaridade(PostModel a, PostModel b) {
    if (a.id == b.id) return 0;
    if (a.isResolved || b.isResolved) return 0;
    if (!tiposOpostos(a.type, b.type)) return 0;
    if (a.species != b.species) return 0;

    final dias = a.eventAt.difference(b.eventAt).inMinutes.abs() / (60 * 24);
    if (dias > AppConstants.similarWindowDays) return 0;

    final km = Geo.distanciaKm(a.latitude, a.longitude, b.latitude, b.longitude);
    if (km > AppConstants.similarMaxKm) return 0;

    final coresInformadas = a.colors.isNotEmpty && b.colors.isNotEmpty;
    final corEmComum = a.colors.any(b.colors.contains);
    final mesmoPorte = a.size == b.size;
    if (coresInformadas && !corEmComum) return 0;
    if (!corEmComum && !mesmoPorte) return 0;

    final proximidade = 1 - km / AppConstants.similarMaxKm; // 1 = mesmo ponto
    return (corEmComum ? 0.4 : 0) + (mesmoPorte ? 0.3 : 0) + 0.3 * proximidade;
  }

  /// Posts de [candidatos] semelhantes a [post], do mais para o menos parecido.
  static List<PostModel> correspondencias(
      PostModel post, List<PostModel> candidatos,
      {int maximo = 5}) {
    final pontuados = [
      for (final c in candidatos)
        if (similaridade(post, c) > 0) (post: c, nota: similaridade(post, c)),
    ]..sort((x, y) => y.nota.compareTo(x.nota));
    return pontuados.take(maximo).map((p) => p.post).toList();
  }
}

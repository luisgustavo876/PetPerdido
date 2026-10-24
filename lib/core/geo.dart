import 'dart:math' as math;

/// Funções de geografia (puras e testáveis).
class Geo {
  Geo._();

  static const _raioTerraKm = 6371.0;

  /// Distância em linha reta entre dois pontos, em km (fórmula de Haversine).
  static double distanciaKm(double lat1, double lng1, double lat2, double lng2) {
    double rad(double graus) => graus * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * _raioTerraKm * math.asin(math.sqrt(a));
  }

  /// Retângulo que contém todos os [pontos] (para enquadrar o mapa).
  /// Se os pontos estiverem muito juntos (ou for um só), abre o retângulo
  /// até [vaoMinimo] graus (~500 m), para o mapa não dar zoom máximo.
  /// Retorna null se a lista estiver vazia.
  static ({double sul, double oeste, double norte, double leste})? limites(
    Iterable<({double lat, double lng})> pontos, {
    double vaoMinimo = 0.005,
  }) {
    if (pontos.isEmpty) return null;
    var sul = double.infinity, norte = -double.infinity;
    var oeste = double.infinity, leste = -double.infinity;
    for (final p in pontos) {
      sul = math.min(sul, p.lat);
      norte = math.max(norte, p.lat);
      oeste = math.min(oeste, p.lng);
      leste = math.max(leste, p.lng);
    }
    if (norte - sul < vaoMinimo) {
      final meio = (norte + sul) / 2;
      sul = meio - vaoMinimo / 2;
      norte = meio + vaoMinimo / 2;
    }
    if (leste - oeste < vaoMinimo) {
      final meio = (leste + oeste) / 2;
      oeste = meio - vaoMinimo / 2;
      leste = meio + vaoMinimo / 2;
    }
    return (sul: sul, oeste: oeste, norte: norte, leste: leste);
  }
}

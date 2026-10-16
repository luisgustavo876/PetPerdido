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
}

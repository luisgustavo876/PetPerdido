import 'package:flutter_test/flutter_test.dart';
import 'package:petperdido/core/geo.dart';

void main() {
  group('Geo.distanciaKm (Haversine)', () {
    test('mesmo ponto = 0', () {
      expect(Geo.distanciaKm(-23.59, -48.05, -23.59, -48.05), 0);
    });

    test('1 grau de latitude ≈ 111,2 km', () {
      expect(Geo.distanciaKm(0, 0, 1, 0), closeTo(111.19, 0.05));
    });

    test('Itapetininga → Sorocaba ≈ 64 km', () {
      // Centro de Itapetininga e centro de Sorocaba
      final km = Geo.distanciaKm(-23.5917, -48.0531, -23.5015, -47.4526);
      expect(km, closeTo(62, 3));
    });

    test('é simétrica', () {
      final ida = Geo.distanciaKm(-23.59, -48.05, -23.60, -48.06);
      final volta = Geo.distanciaKm(-23.60, -48.06, -23.59, -48.05);
      expect(ida, closeTo(volta, 1e-9));
    });

    test('~100 m entre coordenadas arredondadas vizinhas (3 casas)', () {
      expect(Geo.distanciaKm(-23.590, -48.050, -23.591, -48.050),
          closeTo(0.111, 0.002));
    });
  });

  group('Geo.limites (enquadrar o mapa)', () {
    test('lista vazia: null', () {
      expect(Geo.limites(const []), isNull);
    });

    test('contém todos os pontos', () {
      final l = Geo.limites(const [
        (lat: -23.60, lng: -48.06),
        (lat: -23.58, lng: -48.04),
        (lat: -23.59, lng: -48.07),
      ])!;
      expect(l.sul, -23.60);
      expect(l.norte, -23.58);
      expect(l.oeste, -48.07);
      expect(l.leste, -48.04);
    });

    test('um ponto só: abre um vão mínimo centrado nele', () {
      final l = Geo.limites(const [(lat: -23.59, lng: -48.05)])!;
      expect(l.norte - l.sul, closeTo(0.005, 1e-9));
      expect(l.leste - l.oeste, closeTo(0.005, 1e-9));
      expect((l.norte + l.sul) / 2, closeTo(-23.59, 1e-9));
      expect((l.leste + l.oeste) / 2, closeTo(-48.05, 1e-9));
    });
  });
}

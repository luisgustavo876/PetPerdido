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
}

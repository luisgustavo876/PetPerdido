import 'package:flutter_test/flutter_test.dart';
import 'package:petperdido/core/app_constants.dart';
import 'package:petperdido/models/post_model.dart';
import 'package:petperdido/services/location_service.dart';

void main() {
  group('LocationService.arredondar', () {
    test('usa ${AppConstants.coordDecimals} casas decimais por padrão', () {
      expect(LocationService.arredondar(-23.58974), -23.59);
      expect(LocationService.arredondar(-48.05336), -48.053);
      expect(LocationService.arredondar(10.40744), 10.407);
    });

    test('valor já arredondado não muda', () {
      expect(LocationService.arredondar(-23.59), -23.59);
    });

    test('aceita outra precisão', () {
      expect(LocationService.arredondar(-23.58974, casas: 1), -23.6);
    });

    test('geohash do post sai da coordenada já arredondada', () {
      final lat = LocationService.arredondar(-23.58974);
      final lng = LocationService.arredondar(-48.05336);
      expect(PostModel.calcularGeohash(lat, lng),
          PostModel.calcularGeohash(-23.59, -48.053));
    });
  });
}

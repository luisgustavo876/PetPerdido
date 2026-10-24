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

  group('textoDoNominatim (reverso)', () {
    test('com bairro: "Bairro, Cidade" e sem número da casa', () {
      final json = {
        'address': {
          'house_number': '123',
          'road': 'Rua Campos Salles',
          'suburb': 'Vila Barth',
          'city': 'Itapetininga',
          'state': 'São Paulo',
        }
      };
      final texto = LocationService.textoDoNominatim(json);
      expect(texto, 'Vila Barth, Itapetininga');
      expect(texto, isNot(contains('123')));
      expect(texto, isNot(contains('Campos Salles')));
    });

    test('ordem de preferência do bairro: neighbourhood antes de quarter', () {
      final json = {
        'address': {'quarter': 'Q', 'neighbourhood': 'Jardim', 'town': 'Cidade'}
      };
      expect(LocationService.textoDoNominatim(json), 'Jardim, Cidade');
    });

    test('só com rua: usa o nome da rua, nunca o número', () {
      final json = {
        'address': {
          'house_number': '45',
          'road': 'Rua das Flores',
          'city': 'Itapetininga',
        }
      };
      expect(LocationService.textoDoNominatim(json),
          'Rua das Flores, Itapetininga');
    });

    test('sem cidade: só o bairro', () {
      final json = {
        'address': {'suburb': 'Centro'}
      };
      expect(LocationService.textoDoNominatim(json), 'Centro');
    });

    test('vila no lugar de cidade', () {
      final json = {
        'address': {'suburb': 'Centro', 'village': 'Gramadinho'}
      };
      expect(LocationService.textoDoNominatim(json), 'Centro, Gramadinho');
    });

    test('JSON vazio ou sem address retorna null', () {
      expect(LocationService.textoDoNominatim({}), isNull);
      expect(LocationService.textoDoNominatim({'address': {}}), isNull);
      expect(LocationService.textoDoNominatim({'error': 'Unable to geocode'}),
          isNull);
    });
  });

  group('coordenadasDoNominatim (busca)', () {
    test('lê lat/lon (texto) do primeiro resultado', () {
      final pos = LocationService.coordenadasDoNominatim([
        {'lat': '-23.5897', 'lon': '-48.0533'},
        {'lat': '0', 'lon': '0'},
      ]);
      expect(pos?.lat, -23.5897);
      expect(pos?.lng, -48.0533);
    });

    test('lista vazia ou formato inesperado retorna null', () {
      expect(LocationService.coordenadasDoNominatim([]), isNull);
      expect(LocationService.coordenadasDoNominatim(null), isNull);
      expect(LocationService.coordenadasDoNominatim({'lat': '1'}), isNull);
      expect(
          LocationService.coordenadasDoNominatim([
            {'lat': 'x', 'lon': '1'}
          ]),
          isNull);
    });
  });

  group('formatarBairroCidade', () {
    test('ignora partes vazias e repetidas', () {
      expect(LocationService.formatarBairroCidade(' ', 'Itapetininga'),
          'Itapetininga');
      expect(
          LocationService.formatarBairroCidade('Itapetininga', 'Itapetininga'),
          'Itapetininga');
      expect(LocationService.formatarBairroCidade(null, null), isNull);
    });
  });

  group('LocationService.posicaoAtual', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('estadoPermissao sem plugin: "indisponível", sem lançar erro', () async {
      expect(await LocationService.estadoPermissao(),
          EstadoLocalizacao.indisponivel);
    });

    test('plugin ausente (MissingPluginException) vira LocationException', () async {
      // No teste não há plugin nativo: é o mesmo cenário do build da Web que
      // ficou sem o geolocator registrado. Antes, o erro escapava sem tratamento.
      await expectLater(
        LocationService.posicaoAtual(),
        throwsA(isA<LocationException>().having(
            (e) => e.message, 'mensagem', contains('Toque no mapa'))),
      );
    });
  });
}

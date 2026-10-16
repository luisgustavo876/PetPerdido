import 'package:flutter_test/flutter_test.dart';
import 'package:petperdido/core/similaridade.dart';
import 'package:petperdido/models/post_model.dart';
import 'helpers.dart';

void main() {
  final perdido = postDeTeste(id: 'p', type: PostType.lost);
  final achado = postDeTeste(id: 'a', type: PostType.found);

  group('tiposOpostos', () {
    test('Perdi x Achei e Perdi x Avistei são opostos', () {
      expect(Similaridade.tiposOpostos(PostType.lost, PostType.found), isTrue);
      expect(Similaridade.tiposOpostos(PostType.sighted, PostType.lost), isTrue);
    });
    test('Achei x Avistei e mesmo tipo não são', () {
      expect(Similaridade.tiposOpostos(PostType.found, PostType.sighted), isFalse);
      expect(Similaridade.tiposOpostos(PostType.lost, PostType.lost), isFalse);
    });
  });

  group('similaridade', () {
    test('mesmo pet descrito nos dois lados: semelhante', () {
      expect(Similaridade.similaridade(perdido, achado), greaterThan(0));
    });

    test('é simétrica', () {
      expect(Similaridade.similaridade(perdido, achado),
          Similaridade.similaridade(achado, perdido));
    });

    test('mesmo tipo: não', () {
      expect(Similaridade.similaridade(perdido, postDeTeste(id: 'x')), 0);
    });

    test('espécie diferente: não', () {
      expect(
          Similaridade.similaridade(
              perdido, postDeTeste(id: 'x', type: PostType.found, species: 'Gato')),
          0);
    });

    test('mais de 3 km: não', () {
      // ~4,4 km ao norte
      final longe = postDeTeste(id: 'x', type: PostType.found, lat: -23.55);
      expect(Similaridade.similaridade(perdido, longe), 0);
    });

    test('mais de 7 dias entre os ocorridos: não', () {
      final antigo = postDeTeste(
          id: 'x', type: PostType.found, eventAt: DateTime(2026, 10, 8, 12));
      expect(Similaridade.similaridade(perdido, antigo), 0);
      final recente = postDeTeste(
          id: 'y', type: PostType.found, eventAt: DateTime(2026, 10, 10, 12));
      expect(Similaridade.similaridade(perdido, recente), greaterThan(0));
    });

    test('cores informadas sem nenhuma em comum: não', () {
      final outraCor =
          postDeTeste(id: 'x', type: PostType.found, colors: ['Preto']);
      expect(Similaridade.similaridade(perdido, outraCor), 0);
    });

    test('sem cores (post antigo): vale o mesmo porte', () {
      final semCor = postDeTeste(id: 'x', type: PostType.found, colors: []);
      expect(Similaridade.similaridade(perdido, semCor), greaterThan(0));
      final semCorOutroPorte = postDeTeste(
          id: 'y', type: PostType.found, colors: [], size: 'Grande');
      expect(Similaridade.similaridade(perdido, semCorOutroPorte), 0);
    });

    test('resolvido ou o próprio post: não', () {
      expect(
          Similaridade.similaridade(perdido,
              postDeTeste(id: 'x', type: PostType.found, resolvido: true)),
          0);
      expect(Similaridade.similaridade(perdido, perdido), 0);
    });
  });

  test('correspondencias ordena do mais parecido para o menos', () {
    final igual = postDeTeste(id: 'igual', type: PostType.found);
    final outroPorte = postDeTeste(
        id: 'porte', type: PostType.sighted, size: 'Grande', lat: -23.595);
    final distante = postDeTeste(id: 'gato', type: PostType.found, species: 'Gato');
    final lista = Similaridade.correspondencias(
        perdido, [outroPorte, distante, igual]);
    expect(lista.map((p) => p.id), ['igual', 'porte']);
  });
}

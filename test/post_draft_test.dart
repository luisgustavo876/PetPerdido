import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:petperdido/models/post_model.dart';
import 'package:petperdido/screens/post/post_draft.dart';
import 'package:petperdido/screens/post/post_options.dart';

void main() {
  final agora = DateTime(2026, 10, 15, 14, 30);

  /// Rascunho com tudo preenchido corretamente (Perdi).
  PostDraft rascunhoValido() {
    final d = PostDraft()
      ..type = PostType.lost
      ..imageBytes = Uint8List(4)
      ..position = (lat: -23.58974, lng: -48.05336);
    d.colors.add('Caramelo');
    d.petNameController.text = 'Pipoca';
    d.descriptionController.text = 'Cachorro caramelo, coleira azul.';
    d.addressController.text = 'Vila Barth, Itapetininga';
    return d;
  }

  group('validarEtapa', () {
    test('rascunho completo passa em todas as etapas', () {
      expect(rascunhoValido().primeiraEtapaInvalida(agora), isNull);
    });

    test('foto obrigatória em Perdi e Achei, opcional em Avistei', () {
      final d = rascunhoValido()..imageBytes = null;
      expect(d.validarEtapa(1, agora), isNotNull);
      d.type = PostType.found;
      expect(d.validarEtapa(1, agora), isNotNull);
      d.type = PostType.sighted;
      expect(d.validarEtapa(1, agora), isNull);
    });

    test('nome obrigatório só em Perdi', () {
      final d = rascunhoValido();
      d.petNameController.clear();
      expect(d.validarEtapa(2, agora), 'Informe o nome do pet.');
      d.type = PostType.sighted;
      expect(d.validarEtapa(2, agora), isNull);
    });

    test('cor obrigatória e descrição com 10 caracteres', () {
      final d = rascunhoValido();
      d.colors.clear();
      expect(d.validarEtapa(2, agora), 'Escolha pelo menos uma cor.');
      d.colors.add('Preto');
      d.descriptionController.text = 'curto';
      expect(d.validarEtapa(2, agora), contains('10 caracteres'));
    });

    test('etapa 4 exige ponto no mapa', () {
      final d = rascunhoValido()..position = null;
      expect(d.validarEtapa(3, agora), 'Marque no mapa onde o pet foi visto.');
    });

    test('etapa 4 recusa bairro vazio ou "Localização atual"', () {
      final d = rascunhoValido();
      for (final texto in ['', '   ', 'Localização atual', 'localização atual']) {
        d.addressController.text = texto;
        expect(d.validarEtapa(3, agora),
            'Informe o bairro para os outros acharem o pet',
            reason: '"$texto"');
      }
    });

    test('etapa 4 recusa data no futuro', () {
      final d = rascunhoValido()
        ..quando = QuandoAconteceu.escolhido
        ..dataEscolhida = agora.add(const Duration(minutes: 1));
      expect(d.validarEtapa(3, agora), contains('futuro'));
    });
  });

  group('atalhos de data', () {
    test('Agora, Hoje de manhã (9h) e Ontem (12h)', () {
      expect(PostDraft.dataDoAtalho(QuandoAconteceu.agora, agora), agora);
      expect(PostDraft.dataDoAtalho(QuandoAconteceu.hojeDeManha, agora),
          DateTime(2026, 10, 15, 9));
      expect(PostDraft.dataDoAtalho(QuandoAconteceu.ontem, agora),
          DateTime(2026, 10, 14, 12));
    });

    test('"Hoje de manhã" indisponível antes das 9h', () {
      expect(
          PostDraft.dataDoAtalho(
              QuandoAconteceu.hojeDeManha, DateTime(2026, 10, 15, 7)),
          isNull);
    });

    test('"Ontem" no dia 1º vira o último dia do mês anterior', () {
      expect(
          PostDraft.dataDoAtalho(QuandoAconteceu.ontem, DateTime(2026, 3, 1, 8)),
          DateTime(2026, 2, 28, 12));
    });
  });

  group('toPostModel', () {
    final post = rascunhoValido().toPostModel(
      id: 'abc',
      userId: 'u1',
      userName: 'Maria',
      agora: agora,
    );

    test('arredonda as coordenadas do marcador (~100 m)', () {
      expect(post.latitude, -23.59);
      expect(post.longitude, -48.053);
      expect(post.geohash, PostModel.calcularGeohash(-23.59, -48.053));
    });

    test('inclui as cores nas tags e salva cores e data', () {
      expect(post.colors, ['Caramelo']);
      expect(post.tags, containsAll(['Cão', 'Caramelo']));
      expect(post.eventAt, agora); // atalho padrão: Agora
    });

    test('raça vazia vira "Sem raça definida"', () {
      final d = rascunhoValido()..breed = '  ';
      final p = d.toPostModel(id: 'x', userId: 'u', userName: 'n', agora: agora);
      expect(p.breed, PostOptions.racaPadrao);
    });

    test('nome do pet só em Perdi', () {
      final d = rascunhoValido()..type = PostType.found;
      final p = d.toPostModel(id: 'x', userId: 'u', userName: 'n', agora: agora);
      expect(p.petName, 'Sem nome');
    });
  });
}

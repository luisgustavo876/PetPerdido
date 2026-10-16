import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart' show FirebaseAIException;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:petperdido/core/pet_options.dart';
import 'package:petperdido/models/sugestao_ia.dart';
import 'package:petperdido/screens/post/post_draft.dart';
import 'package:petperdido/services/ai_service.dart';

void main() {
  group('SugestaoIA.converter — respostas boas', () {
    test('resposta completa dentro das listas', () {
      final s = SugestaoIA.converter('''
        {"species": "Cão", "size": "Médio", "colors": ["Caramelo", "Branco"],
         "breed": "Vira-lata caramelo", "traits": ["Com Coleira", "Dócil"]}''')!;
      expect(s.especie, 'Cão');
      expect(s.porte, 'Médio');
      expect(s.cores, ['Caramelo', 'Branco']);
      expect(s.raca, 'Vira-lata caramelo');
      expect(s.caracteristicas, ['Com Coleira', 'Dócil']);
      expect(s.naoEhPet, isFalse);
    });

    test('ignora maiúsculas/minúsculas e normaliza para o valor do app', () {
      final s = SugestaoIA.converter(
          '{"species": "gato", "size": "pequeno", "colors": ["PRETO"]}')!;
      expect(s.especie, 'Gato');
      expect(s.porte, 'Pequeno');
      expect(s.cores, ['Preto']);
    });

    test('aceita JSON dentro de cercas de código', () {
      final s = SugestaoIA.converter('```json\n{"species": "Cão"}\n```');
      expect(s?.especie, 'Cão');
    });
  });

  group('SugestaoIA.converter — respostas ruins', () {
    test('valores fora das listas são descartados', () {
      final s = SugestaoIA.converter('''
        {"species": "Coelho", "size": "Gigante", "colors": ["Roxo", "Preto"],
         "traits": ["Voa", "Ferido"]}''')!;
      expect(s.especie, isNull); // não é cão nem gato
      expect(s.naoEhPet, isTrue);
      expect(s.porte, isNull);
      expect(s.cores, ['Preto']);
      expect(s.caracteristicas, ['Ferido']);
    });

    test('no máximo 2 cores, sem repetir', () {
      final s = SugestaoIA.converter(
          '{"species": "Cão", "colors": ["Preto", "Preto", "Branco", "Cinza"]}')!;
      expect(s.cores, ['Preto', 'Branco']);
      expect(s.cores.length, PetOptions.maxCores);
    });

    test('"Indefinido" = não é um pet', () {
      final s = SugestaoIA.converter('{"species": "Indefinido"}')!;
      expect(s.naoEhPet, isTrue);
    });

    test('raça vazia, "Indefinido" ou muito longa', () {
      expect(SugestaoIA.converter('{"species":"Cão","breed":""}')!.raca,
          PetOptions.racaPadrao);
      expect(SugestaoIA.converter('{"species":"Cão","breed":"Indefinido"}')!.raca,
          PetOptions.racaPadrao);
      final longa = SugestaoIA.converter(
          '{"species":"Cão","breed":"${'x' * 100}"}')!.raca;
      expect(longa.length, lessThanOrEqualTo(40));
    });

    test('tipos errados nos campos não quebram', () {
      final s = SugestaoIA.converter(
          '{"species": 3, "size": null, "colors": "Preto", "traits": {}}')!;
      expect(s.especie, isNull);
      expect(s.cores, isEmpty);
      expect(s.caracteristicas, isEmpty);
    });
  });

  group('SugestaoIA.converter — respostas vazias ou inválidas', () {
    test('null, vazio, texto solto e JSON que não é objeto', () {
      expect(SugestaoIA.converter(null), isNull);
      expect(SugestaoIA.converter('   '), isNull);
      expect(SugestaoIA.converter('não sei dizer'), isNull);
      expect(SugestaoIA.converter('[1, 2]'), isNull);
    });
  });

  group('aplicarSugestao no formulário', () {
    test('preenche os campos e marca o selo; continua editável', () {
      final d = PostDraft();
      d.aplicarSugestao(const SugestaoIA(
        especie: 'Gato',
        porte: 'Pequeno',
        cores: ['Preto', 'Branco'],
        raca: 'Siamês',
        caracteristicas: ['Olhos Azuis'],
      ));
      expect(d.species, 'Gato');
      expect(d.size, 'Pequeno');
      expect(d.colors, {'Preto', 'Branco'});
      expect(d.breed, 'Siamês');
      expect(d.traits, contains('Olhos Azuis'));
      expect(d.sugeridosPelaIA,
          {'especie', 'porte', 'cores', 'raca', 'caracteristicas'});
      d.dispose();
    });
  });

  group('AIService.mensagemDeErro', () {
    test('tempo esgotado, cota, API desativada, outros e sem internet', () {
      expect(AIService.mensagemDeErro(TimeoutException('x')), contains('demorou'));
      expect(
          AIService.mensagemDeErro(
              FirebaseAIException('Quota exceeded for quota metric')),
          contains('limite'));
      expect(
          AIService.mensagemDeErro(FirebaseAIException(
              'Firebase AI Logic API (firebasevertexai.googleapis.com) has not been used')),
          contains('não foi ativada'));
      expect(AIService.mensagemDeErro(FirebaseAIException('erro 500')),
          contains('não conseguiu responder'));
      expect(AIService.mensagemDeErro(Exception('SocketException')),
          contains('sem internet'));
    });
  });

  group('reduzirFoto', () {
    Uint8List jpeg(int largura, int altura) => Uint8List.fromList(
        img.encodeJpg(img.Image(width: largura, height: altura)));

    test('foto grande fica com no máximo 1024 px no maior lado', () {
      final saida = img.decodeImage(reduzirFoto(jpeg(2000, 1500)))!;
      expect(saida.width, 1024);
      expect(saida.height, 768);
    });

    test('foto em pé também', () {
      final saida = img.decodeImage(reduzirFoto(jpeg(900, 1800)))!;
      expect(saida.height, 1024);
      expect(saida.width, 512);
    });

    test('foto pequena mantém o tamanho', () {
      final saida = img.decodeImage(reduzirFoto(jpeg(640, 480)))!;
      expect(saida.width, 640);
    });

    test('bytes que não são imagem voltam como estão', () {
      final lixo = Uint8List.fromList([1, 2, 3]);
      expect(reduzirFoto(lixo), lixo);
    });
  });
}

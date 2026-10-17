import 'package:flutter_test/flutter_test.dart';
import 'package:petperdido/core/formatters.dart';
import 'package:petperdido/models/post_filter.dart';
import 'helpers.dart';

void main() {
  group('normalizar', () {
    test('minúsculas e sem acentos', () {
      expect(Formatters.normalizar('Cão Caramelo ÇÃO'), 'cao caramelo cao');
      expect(Formatters.normalizar('Jardim Marabá'), 'jardim maraba');
    });
  });

  group('data e lerData (DD/MM/AAAA)', () {
    test('formata no padrão brasileiro', () {
      expect(Formatters.data(DateTime(2006, 6, 9)), '09/06/2006');
    });

    test('lê com ou sem barras', () {
      expect(Formatters.lerData('29/06/2006'), DateTime(2006, 6, 29));
      expect(Formatters.lerData('29062006'), DateTime(2006, 6, 29));
    });

    test('incompleta ou inexistente devolve null', () {
      expect(Formatters.lerData('29/06/20'), isNull);
      expect(Formatters.lerData('31/04/2006'), isNull);
      expect(Formatters.lerData('10/10/1899'), isNull);
    });
  });

  group('tempoRelativo', () {
    final agora = DateTime(2026, 10, 16, 12);
    test('minutos, horas e dias', () {
      expect(Formatters.tempoRelativo(agora, agora), 'agora');
      expect(Formatters.tempoRelativo(
          agora.subtract(const Duration(minutes: 5)), agora), 'há 5 min');
      expect(Formatters.tempoRelativo(
          agora.subtract(const Duration(hours: 2)), agora), 'há 2 h');
      expect(Formatters.tempoRelativo(
          agora.subtract(const Duration(days: 1)), agora), 'há 1 dia');
      expect(Formatters.tempoRelativo(
          agora.subtract(const Duration(days: 3)), agora), 'há 3 dias');
    });
    test('mais de 30 dias mostra a data', () {
      expect(Formatters.tempoRelativo(DateTime(2026, 8, 1), agora),
          'em 01/08/2026');
    });
  });

  group('distancia', () {
    test('metros, km com vírgula e km inteiros', () {
      expect(Formatters.distancia(0.347), 'a 350 m');
      expect(Formatters.distancia(0.001), 'a 10 m');
      expect(Formatters.distancia(1.24), 'a 1,2 km');
      expect(Formatters.distancia(15.6), 'a 16 km');
    });
  });

  group('textoCompartilhar', () {
    test('tem tipo, pet, descrição, bairro e o nome do app', () {
      final texto = Formatters.textoCompartilhar(postDeTeste(
          colors: ['Preto'], description: 'Sumiu perto da praça.'));
      expect(texto, contains('PERDI MEU PET: Pipoca'));
      expect(texto, contains('Preto'));
      expect(texto, contains('Sumiu perto da praça.'));
      expect(texto, contains('Região: Centro, Itapetininga'));
      expect(texto, contains('PetPerdido'));
    });

    test('não expõe coordenadas nem link falso', () {
      final texto = Formatters.textoCompartilhar(postDeTeste());
      expect(texto, isNot(contains('-23.59')));
      expect(texto, isNot(contains('http')));
    });
  });

  group('PostFilter.buscaCorresponde', () {
    final post = postDeTeste(
      petName: 'Pipoca',
      breed: 'Golden Retriever',
      colors: ['Dourado'],
      traits: ['Dócil'],
      endereco: 'Jardim Marabá, Itapetininga',
    );

    test('busca vazia aceita tudo', () {
      expect(PostFilter.buscaCorresponde(post, '  '), isTrue);
    });

    test('nome, raça, cor, bairro e características, sem acento', () {
      expect(PostFilter.buscaCorresponde(post, 'pipoca'), isTrue);
      expect(PostFilter.buscaCorresponde(post, 'golden'), isTrue);
      expect(PostFilter.buscaCorresponde(post, 'DOURADO'), isTrue);
      expect(PostFilter.buscaCorresponde(post, 'maraba'), isTrue);
      expect(PostFilter.buscaCorresponde(post, 'docil'), isTrue);
    });

    test('todas as palavras precisam aparecer', () {
      expect(PostFilter.buscaCorresponde(post, 'golden maraba'), isTrue);
      expect(PostFilter.buscaCorresponde(post, 'golden centro'), isFalse);
    });
  });
}

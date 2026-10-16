import 'package:flutter_test/flutter_test.dart';
import 'package:petperdido/core/filtro_palavroes.dart';
import 'package:petperdido/models/chat_model.dart';
import 'package:petperdido/models/post_model.dart';
import 'package:petperdido/services/chat_service.dart';
import 'helpers.dart';

void main() {
  group('FiltroPalavroes', () {
    test('troca palavrões por ***, ignorando acentos e maiúsculas', () {
      expect(FiltroPalavroes.filtrar('Que PORRA é essa'), 'Que *** é essa');
      expect(FiltroPalavroes.filtrar('seu otário'), 'seu ***');
      expect(FiltroPalavroes.filtrar('Desgraçado!'), '***!');
    });

    test('mantém o resto do texto (pontuação, números, espaços)', () {
      expect(FiltroPalavroes.filtrar('Vi o cão às 14h, perto da praça.'),
          'Vi o cão às 14h, perto da praça.');
    });

    test('só palavras inteiras (não censura "cuidado" nem "computador")', () {
      expect(FiltroPalavroes.filtrar('cuidado com o computador'),
          'cuidado com o computador');
      expect(FiltroPalavroes.filtrar('cu'), '***');
    });

    test('palavras ambíguas do dia a dia não são censuradas', () {
      expect(FiltroPalavroes.filtrar('um pau de madeira e a bola rola'),
          'um pau de madeira e a bola rola');
    });

    test('contemPalavrao', () {
      expect(FiltroPalavroes.contemPalavrao('merda'), isTrue);
      expect(FiltroPalavroes.contemPalavrao('obrigado!'), isFalse);
    });
  });

  group('ChatModel', () {
    test('idPara é determinístico e não depende da ordem dos uids', () {
      expect(ChatModel.idPara('p1', 'zeta', 'alfa'), 'p1_alfa_zeta');
      expect(ChatModel.idPara('p1', 'alfa', 'zeta'), 'p1_alfa_zeta');
    });

    test('outro, nomeDoOutro e naoLidas (só nomes, nada de e-mail/CPF)', () {
      final c = ChatModel.fromMap('p1_a_b', {
        'participants': ['a', 'b'],
        'participantNames': {'a': 'Ana', 'b': 'Bruno'},
        'postId': 'p1',
        'postTitle': 'Pipoca · Perdi meu Pet',
        'lastMessage': 'Oi',
        'unread': {'a': 2, 'b': 0},
      });
      expect(c.outro('a'), 'b');
      expect(c.nomeDoOutro('a'), 'Bruno');
      expect(c.naoLidas('a'), 2);
      expect(c.naoLidas('b'), 0);
    });

    test('documento incompleto não quebra', () {
      final c = ChatModel.fromMap('x', {});
      expect(c.participants, isEmpty);
      expect(c.nomeDoOutro('a'), 'Usuário');
    });
  });

  group('ChatService', () {
    test('mensagens com mais de 15 dias não aparecem', () {
      final agora = DateTime(2026, 10, 16, 12);
      expect(ChatService.visivel(agora.subtract(const Duration(days: 14)), agora), isTrue);
      expect(ChatService.visivel(agora.subtract(const Duration(days: 15)), agora), isTrue);
      expect(
          ChatService.visivel(
              agora.subtract(const Duration(days: 15, minutes: 1)), agora),
          isFalse);
    });

    test('título da conversa: nome do pet (ou espécie) e tipo', () {
      expect(ChatService.tituloDoPost(postDeTeste()), 'Pipoca · Perdi meu Pet');
      expect(
          ChatService.tituloDoPost(
              postDeTeste(type: PostType.found, petName: 'Sem nome')),
          'Cão · Achei um Pet');
    });
  });
}

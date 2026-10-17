import 'package:flutter_test/flutter_test.dart';
import 'package:petperdido/core/app_constants.dart';
import 'package:petperdido/services/auth_service.dart';

void main() {
  group('validarCpf', () {
    test('aceita CPF válido', () {
      expect(AuthService.validarCpf('52998224725'), isTrue);
      expect(AuthService.validarCpf('12345678909'), isTrue);
    });

    test('aceita CPF válido com máscara', () {
      expect(AuthService.validarCpf('529.982.247-25'), isTrue);
    });

    test('rejeita dígito verificador errado', () {
      expect(AuthService.validarCpf('52998224724'), isFalse); // 2º dígito
      expect(AuthService.validarCpf('52998224715'), isFalse); // 1º dígito
    });

    test('rejeita todos os dígitos iguais', () {
      for (var n = 0; n <= 9; n++) {
        expect(AuthService.validarCpf('$n' * 11), isFalse, reason: '$n' * 11);
      }
      expect(AuthService.validarCpf('111.111.111-11'), isFalse);
    });

    test('rejeita tamanho errado e texto vazio', () {
      expect(AuthService.validarCpf('5299822472'), isFalse);
      expect(AuthService.validarCpf('529982247250'), isFalse);
      expect(AuthService.validarCpf(''), isFalse);
    });
  });

  group('idadeEmAnos', () {
    final hoje = DateTime(2026, 10, 15);

    test('15 anos e 364 dias ainda tem 15 anos', () {
      expect(AuthService.idadeEmAnos(DateTime(2010, 10, 16), hoje), 15);
    });

    test('16 anos exatos no dia do aniversário', () {
      expect(AuthService.idadeEmAnos(DateTime(2010, 10, 15), hoje), 16);
    });

    test('ignora o horário do dia', () {
      expect(
        AuthService.idadeEmAnos(
            DateTime(2010, 10, 15, 23, 59), DateTime(2026, 10, 15, 0, 1)),
        16,
      );
    });

    test('nascido em 29/02: aniversário em ano bissexto', () {
      final nasc = DateTime(2008, 2, 29);
      expect(AuthService.idadeEmAnos(nasc, DateTime(2024, 2, 28)), 15);
      expect(AuthService.idadeEmAnos(nasc, DateTime(2024, 2, 29)), 16);
    });

    test('nascido em 29/02: em ano não bissexto completa em 01/03', () {
      final nasc = DateTime(2008, 2, 29);
      expect(AuthService.idadeEmAnos(nasc, DateTime(2025, 2, 28)), 16);
      expect(AuthService.idadeEmAnos(nasc, DateTime(2025, 3, 1)), 17);
    });
  });

  group('validarNascimento (regra do cadastro)', () {
    final hoje = DateTime(2026, 10, 15);

    test('bloqueia menor de ${AppConstants.minAge} anos', () {
      expect(AuthService.validarNascimento(DateTime(2010, 10, 16), hoje),
          isNotNull);
    });

    test('aprova quem tem ${AppConstants.minAge} anos exatos', () {
      expect(AuthService.validarNascimento(DateTime(2010, 10, 15), hoje),
          isNull);
    });

    test('exige a data e rejeita data no futuro', () {
      expect(AuthService.validarNascimento(null, hoje), isNotNull);
      expect(AuthService.validarNascimento(DateTime(2027, 1, 1), hoje),
          isNotNull);
    });
  });

  group('validarNascimentoTexto (campo DD/MM/AAAA)', () {
    final hoje = DateTime(2026, 10, 15);
    String? validar(String t) => AuthService.validarNascimentoTexto(t, hoje);

    test('aceita data real com idade suficiente', () {
      expect(validar('29/06/2006'), isNull);
      expect(validar('15/10/2010'), isNull); // 16 anos exatos
    });

    test('vazio e incompleto têm mensagens próprias', () {
      expect(validar(''), 'Informe a data de nascimento');
      expect(validar('29/06/20'), contains('incompleta'));
    });

    test('rejeita dia ou mês que não existem', () {
      expect(validar('31/02/2006'), contains('inválida'));
      expect(validar('29/02/2007'), contains('inválida')); // não bissexto
      expect(validar('15/13/2006'), contains('inválida'));
      expect(validar('00/06/2006'), contains('inválida'));
    });

    test('aceita 29/02 em ano bissexto', () {
      expect(validar('29/02/2008'), isNull);
    });

    test('rejeita futuro e menor de ${AppConstants.minAge} anos', () {
      expect(validar('01/01/2027'), contains('futuro'));
      expect(validar('16/10/2010'), contains('${AppConstants.minAge} anos'));
    });
  });
}

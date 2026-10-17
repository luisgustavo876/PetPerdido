import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petperdido/core/input_formatters.dart';

/// Simula a digitação: aplica o formatter de [anterior] para [novo], com o
/// cursor no fim (ou em [cursor]).
TextEditingValue digitar(TextInputFormatter f, String anterior, String novo,
    {int? cursor}) {
  return f.formatEditUpdate(
    TextEditingValue(
        text: anterior,
        selection: TextSelection.collapsed(offset: anterior.length)),
    TextEditingValue(
        text: novo,
        selection: TextSelection.collapsed(offset: cursor ?? novo.length)),
  );
}

void main() {
  group('MascaraInputFormatter.cpf', () {
    final f = MascaraInputFormatter.cpf();

    test('formata enquanto digita', () {
      expect(digitar(f, '', '5').text, '5');
      expect(digitar(f, '529', '5299').text, '529.9');
      expect(digitar(f, '', '52998224725').text, '529.982.247-25');
    });

    test('não põe separador sobrando no fim', () {
      expect(digitar(f, '52', '529').text, '529');
      expect(digitar(f, '', '529982247').text, '529.982.247');
    });

    test('aceita só dígitos e no máximo 11', () {
      expect(digitar(f, '', '52a9b8').text, '529.8');
      expect(digitar(f, '', '529982247251234').text, '529.982.247-25');
    });

    test('colar com máscara mantém o mesmo resultado', () {
      expect(digitar(f, '', '529.982.247-25').text, '529.982.247-25');
    });

    test('backspace no separador apaga o dígito anterior', () {
      // "529.9" → apagou o "9" final → "529"
      expect(digitar(f, '529.9', '529.').text, '529');
      // "529.982.247-25" com o cursor depois do "-": apagou o "-"
      final r = digitar(f, '529.982.247-25', '529.982.24725', cursor: 11);
      expect(r.text, '529.982.242-5');
      expect(r.selection.end, 10);
    });

    test('cursor fica no lugar ao editar no meio', () {
      // Insere "0" depois do primeiro dígito.
      final r = digitar(f, '529.982', '5029.982', cursor: 2);
      expect(r.text, '502.998.2');
      expect(r.selection.end, 2);
    });
  });
}

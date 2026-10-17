import 'package:flutter/services.dart';

/// Máscara de digitação só com números (sem dependência externa).
///
/// O usuário digita apenas os dígitos e os separadores do [padrao] aparecem
/// sozinhos. Cada `#` do padrão é um dígito; o resto é separador.
/// Ex.: padrão `###.###.###-##` transforma "52998224725" em "529.982.247-25".
class MascaraInputFormatter extends TextInputFormatter {
  final String padrao;

  MascaraInputFormatter(this.padrao);

  /// CPF: 000.000.000-00.
  factory MascaraInputFormatter.cpf() => MascaraInputFormatter('###.###.###-##');

  /// Data: DD/MM/AAAA (8 dígitos).
  factory MascaraInputFormatter.data() => MascaraInputFormatter('##/##/####');

  /// Quantidade máxima de dígitos aceitos pelo padrão.
  int get maxDigitos => '#'.allMatches(padrao).length;

  /// Aplica o padrão a [digitos]. O separador só aparece quando há um dígito
  /// depois dele ("123" e não "123.").
  String aplicar(String digitos) {
    final buffer = StringBuffer();
    var i = 0;
    for (final c in padrao.split('')) {
      if (i >= digitos.length) break;
      if (c == '#') {
        buffer.write(digitos[i]);
        i++;
      } else {
        buffer.write(c);
      }
    }
    return buffer.toString();
  }

  static String _soDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digitos = _soDigitos(newValue.text);
    final cursor = newValue.selection.isValid
        ? newValue.selection.end.clamp(0, newValue.text.length)
        : newValue.text.length;
    var digitosAntesDoCursor =
        _soDigitos(newValue.text.substring(0, cursor)).length;

    // Apagou só um separador (ex.: o "-"): apaga também o dígito antes dele,
    // senão o separador volta e o backspace parece travado.
    final apagouSeparador = newValue.text.length < oldValue.text.length &&
        digitos == _soDigitos(oldValue.text);
    if (apagouSeparador && digitosAntesDoCursor > 0) {
      digitos = digitos.substring(0, digitosAntesDoCursor - 1) +
          digitos.substring(digitosAntesDoCursor);
      digitosAntesDoCursor--;
    }

    if (digitos.length > maxDigitos) digitos = digitos.substring(0, maxDigitos);
    if (digitosAntesDoCursor > digitos.length) {
      digitosAntesDoCursor = digitos.length;
    }

    final texto = aplicar(digitos);

    // Cursor logo depois do mesmo dígito em que estava.
    var posicao = 0;
    var contados = 0;
    while (posicao < texto.length && contados < digitosAntesDoCursor) {
      if (RegExp(r'\d').hasMatch(texto[posicao])) contados++;
      posicao++;
    }

    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: posicao),
    );
  }
}

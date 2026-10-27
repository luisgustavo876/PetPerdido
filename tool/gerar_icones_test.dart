// Gera os ícones do PetPerdido (pata branca sobre o vermelho do app):
// site (favicon, ícones do PWA), selo da notificação no navegador e ícone
// pequeno da notificação no Android.
//
// Para gerar de novo:  flutter test tool/gerar_icones_test.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _vermelho = Color(0xFFE53935);

/// Pata desenhada num quadrado de 100 x 100 (almofada + 4 dedos).
void _pata(Canvas canvas, Paint tinta) {
  canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 67), width: 46, height: 37), tinta);
  for (final (x, y, l, a, graus) in const [
    (37.0, 33.0, 15.5, 21.0, -14.0),
    (63.0, 33.0, 15.5, 21.0, 14.0),
    (21.5, 49.0, 13.5, 18.0, -36.0),
    (78.5, 49.0, 13.5, 18.0, 36.0),
  ]) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(graus * math.pi / 180);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: l, height: a), tinta);
    canvas.restore();
  }
}

/// Desenha [lado] x [lado] px e grava PNG em [caminho].
Future<void> _gerar(String caminho, int lado,
    {Color? fundo, double raioFundo = 0, double pata = 0.62}) async {
  final gravador = ui.PictureRecorder();
  final canvas = Canvas(gravador);
  final s = lado.toDouble();
  if (fundo != null) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, s, s), Radius.circular(s * raioFundo)),
        Paint()..color = fundo);
  }
  // Pata centrada, ocupando a fração [pata] do lado.
  final escala = s * pata / 100;
  canvas.translate((s - 100 * escala) / 2, (s - 100 * escala) / 2 - s * 0.01);
  canvas.scale(escala);
  _pata(canvas, Paint()..color = Colors.white..isAntiAlias = true);

  final imagem = await gravador.endRecording().toImage(lado, lado);
  final png = await imagem.toByteData(format: ui.ImageByteFormat.png);
  final arquivo = File(caminho)..createSync(recursive: true);
  arquivo.writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  testWidgets('gera os ícones', (tester) async {
    await tester.runAsync(() async {
      // Site / PWA: quadrado vermelho de cantos arredondados e pata branca.
      await _gerar('web/favicon.png', 64, fundo: _vermelho, raioFundo: 0.22);
      await _gerar('web/icons/Icon-192.png', 192, fundo: _vermelho, raioFundo: 0.22);
      await _gerar('web/icons/Icon-512.png', 512, fundo: _vermelho, raioFundo: 0.22);
      // "maskable": o sistema recorta em círculo/gota; pata dentro da zona segura.
      await _gerar('web/icons/Icon-maskable-192.png', 192, fundo: _vermelho, pata: 0.5);
      await _gerar('web/icons/Icon-maskable-512.png', 512, fundo: _vermelho, pata: 0.5);
      // Selo da notificação no navegador (barra de status): só a silhueta branca.
      await _gerar('web/icons/badge-96.png', 96, pata: 0.86);
      // Ícone pequeno da notificação no app Android (silhueta branca).
      for (final (pasta, lado) in const [
        ('mdpi', 24), ('hdpi', 36), ('xhdpi', 48), ('xxhdpi', 72), ('xxxhdpi', 96),
      ]) {
        await _gerar('android/app/src/main/res/drawable-$pasta/ic_notification.png',
            lado, pata: 0.86);
      }
    });
  });
}

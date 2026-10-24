import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/post_type_style.dart';
import '../models/post_model.dart';

/// Pinos coloridos do mapa, desenhados pelo próprio app.
///
/// O mapa da Web ignora a cor dos pinos padrão (`defaultMarkerWithHue`):
/// perdidos, avistados, achados e até "você está aqui" saíam todos vermelhos.
/// Aqui as imagens são geradas uma vez (nas cores da legenda) e servem para a
/// Web e o Android. Enquanto não ficam prontas, vale o pino padrão.
class IconesMapa {
  IconesMapa._();

  static final Map<String, BitmapDescriptor> _cache = {};
  static Future<void>? _carregando;

  /// Gera os ícones (uma vez só por execução do app).
  static Future<void> carregar() => _carregando ??= _gerarTodos();

  static Future<void> _gerarTodos() async {
    try {
      for (final tipo in PostType.values) {
        _cache[tipo.value] = await _pino(tipo.color);
      }
      _cache['eu'] = await _ponto(const Color(0xFF1A73E8));
    } catch (e) {
      debugPrint('IconesMapa: ficam os pinos padrão ($e)');
    }
  }

  /// Pino do tipo do post (cor da legenda).
  static BitmapDescriptor doTipo(PostType tipo) =>
      _cache[tipo.value] ??
      BitmapDescriptor.defaultMarkerWithHue(switch (tipo) {
        PostType.lost => BitmapDescriptor.hueRed,
        PostType.found => BitmapDescriptor.hueGreen,
        PostType.sighted => BitmapDescriptor.hueOrange,
      });

  /// Ponto azul de "você está aqui" (âncora no centro).
  static BitmapDescriptor get euEstouAqui =>
      _cache['eu'] ??
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);

  /// Âncora do [euEstouAqui]: o centro do ponto (o pino padrão usa a ponta).
  static Offset get ancoraEuEstouAqui =>
      _cache.containsKey('eu') ? const Offset(0.5, 0.5) : const Offset(0.5, 1);

  static const _escala = 3.0; // desenha em alta resolução (telas densas)

  /// Gota com ponta embaixo (a ponta marca o lugar) e miolo branco.
  static Future<BitmapDescriptor> _pino(Color cor) async {
    const largura = 34.0, altura = 46.0;
    const centro = Offset(largura / 2, largura / 2);
    const raio = largura / 2 - 2;
    final gota = Path.combine(
      PathOperation.union,
      Path()..addOval(Rect.fromCircle(center: centro, radius: raio)),
      Path()
        ..moveTo(centro.dx - raio * 0.66, centro.dy + raio * 0.75)
        ..lineTo(largura / 2, altura - 2)
        ..lineTo(centro.dx + raio * 0.66, centro.dy + raio * 0.75)
        ..close(),
    );
    return _desenhar(largura, altura, (canvas) {
      canvas.drawShadow(gota, Colors.black, 2, false);
      canvas.drawPath(gota, Paint()..color = cor);
      canvas.drawPath(
          gota,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      canvas.drawCircle(centro, raio * 0.38, Paint()..color = Colors.white);
    });
  }

  /// Ponto com borda branca e um halo claro.
  static Future<BitmapDescriptor> _ponto(Color cor) async {
    const lado = 24.0;
    const centro = Offset(lado / 2, lado / 2);
    return _desenhar(lado, lado, (canvas) {
      canvas.drawCircle(centro, lado / 2, Paint()..color = cor.withValues(alpha: 0.25));
      canvas.drawCircle(centro, 7.5, Paint()..color = Colors.white);
      canvas.drawCircle(centro, 5.5, Paint()..color = cor);
    });
  }

  static Future<BitmapDescriptor> _desenhar(
      double largura, double altura, void Function(Canvas) pintar) async {
    final gravador = ui.PictureRecorder();
    final canvas = Canvas(gravador)..scale(_escala);
    pintar(canvas);
    final imagem = await gravador
        .endRecording()
        .toImage((largura * _escala).round(), (altura * _escala).round());
    final png = await imagem.toByteData(format: ui.ImageByteFormat.png);
    imagem.dispose();
    return BitmapDescriptor.bytes(png!.buffer.asUint8List(),
        width: largura, height: altura);
  }
}

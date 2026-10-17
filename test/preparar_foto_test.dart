import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:petperdido/core/app_constants.dart';
import 'package:petperdido/services/storage_service.dart';

Uint8List png(int w, int h) =>
    Uint8List.fromList(img.encodePng(img.Image(width: w, height: h)));

Uint8List jpg(int w, int h) =>
    Uint8List.fromList(img.encodeJpg(img.Image(width: w, height: h)));

img.Image ler(Uint8List bytes) => img.decodeImage(bytes)!;

void main() {
  const maximo = AppConstants.fotoMaxPixels;

  group('prepararFoto (upload sem recorte)', () {
    test('foto larga é reduzida mantendo a proporção', () {
      final r = ler(prepararFoto(png(3200, 1200)));
      expect(r.width, maximo);
      expect(r.height, 600); // 3200x1200 → 1600x600
    });

    test('foto alta é reduzida pelo lado maior (altura)', () {
      final r = ler(prepararFoto(png(1200, 2400)));
      expect(r.height, maximo);
      expect(r.width, 800);
    });

    test('JPEG que já cabe vai como está (sem recomprimir)', () {
      final original = jpg(1000, 800);
      expect(prepararFoto(original), same(original));
    });

    test('PNG pequeno vira JPEG do mesmo tamanho', () {
      final saida = prepararFoto(png(400, 300));
      expect(saida[0], 0xFF); // JPEG começa com FF D8
      expect(saida[1], 0xD8);
      final r = ler(saida);
      expect((r.width, r.height), (400, 300));
    });

    test('resultado fica abaixo do limite de 5 MB', () {
      expect(prepararFoto(png(4000, 3000)).length,
          lessThan(AppConstants.fotoMaxBytes));
    });

    test('bytes que não são imagem voltam como estão', () {
      final lixo = Uint8List.fromList([1, 2, 3, 4]);
      expect(prepararFoto(lixo), same(lixo));
    });
  });
}

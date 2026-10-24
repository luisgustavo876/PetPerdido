import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:petperdido/models/post_model.dart';
import 'package:petperdido/widgets/icones_mapa.dart';

void main() {
  testWidgets('gera um pino desenhado (imagem) para cada tipo e o ponto azul',
      (tester) async {
    await tester.runAsync(IconesMapa.carregar);

    final icones = [for (final t in PostType.values) IconesMapa.doTipo(t)];
    for (final icone in icones) {
      expect(icone, isA<BytesMapBitmap>());
      expect((icone as BytesMapBitmap).byteData, isNotEmpty);
    }
    // Cores diferentes = imagens diferentes.
    final bytes = icones.map((i) => (i as BytesMapBitmap).byteData.length).toSet();
    expect(icones.toSet(), hasLength(3), reason: '$bytes');

    expect(IconesMapa.euEstouAqui, isA<BytesMapBitmap>());
    expect(IconesMapa.ancoraEuEstouAqui, const Offset(0.5, 0.5));
  });
}

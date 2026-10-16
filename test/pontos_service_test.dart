import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:petperdido/core/app_constants.dart';
import 'package:petperdido/core/recompensas.dart';
import 'package:petperdido/models/post_model.dart';
import 'package:petperdido/services/pontos_service.dart';

void main() {
  group('pontosPorPost', () {
    test('Achei +30, Avistei +10, Perdi 0', () {
      expect(PontosService.pontosPorPost(PostType.found), AppConstants.pontosAchei);
      expect(PontosService.pontosPorPost(PostType.sighted), AppConstants.pontosAvistei);
      expect(PontosService.pontosPorPost(PostType.lost), 0);
      expect(AppConstants.pontosAchei, 30);
      expect(AppConstants.pontosAvistei, 10);
      expect(AppConstants.pontosEuVi, 15);
    });
  });

  group('gerarCodigo', () {
    test('formato PET-XXXX-XXXX sem caracteres que confundem', () {
      final aleatorio = Random(42);
      for (var i = 0; i < 200; i++) {
        final codigo = PontosService.gerarCodigo(aleatorio);
        expect(codigo, matches(RegExp(r'^PET-[A-Z2-9]{4}-[A-Z2-9]{4}$')));
        expect(codigo.substring(4), isNot(matches(RegExp('[01OI]'))));
      }
    });

    test('mesma semente = mesmo código (função pura)', () {
      expect(PontosService.gerarCodigo(Random(7)),
          PontosService.gerarCodigo(Random(7)));
    });
  });

  group('nivel', () {
    test('faixas e próximo nível', () {
      expect(PontosService.nivel(0).nome, 'Vizinho atento');
      expect(PontosService.nivel(0).proximo, 50);
      expect(PontosService.nivel(50).nome, 'Ajudante da rua');
      expect(PontosService.nivel(149).proximo, 150);
      expect(PontosService.nivel(150).nome, 'Protetor do bairro');
      expect(PontosService.nivel(1000).nome, 'Herói dos pets');
      expect(PontosService.nivel(1000).proximo, isNull);
    });
  });

  test('catálogo: ids únicos, custos positivos e sem marcas reais', () {
    final ids = catalogoRecompensas.map((r) => r.id).toSet();
    expect(ids.length, catalogoRecompensas.length);
    expect(catalogoRecompensas.every((r) => r.custo > 0), isTrue);
    expect(Recompensa.parceiroExemplo, 'Exemplo de parceria');
  });
}

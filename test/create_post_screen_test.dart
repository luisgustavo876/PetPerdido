import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petperdido/screens/post/create_post_screen.dart';

/// Percorre as etapas 1 a 3 do formulário (as etapas 4 e 5 usam o mapa
/// e fontes da internet, que não existem no ambiente de teste).
void main() {
  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: CreatePostScreen()));
  }

  Future<void> avancar(WidgetTester tester) async {
    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra o indicador com os rótulos das etapas', (tester) async {
    await abrir(tester);
    for (final rotulo in ['Tipo', 'Foto', 'Pet', 'Local', 'Revisar']) {
      expect(find.text(rotulo), findsOneWidget);
    }
    expect(find.text('Qual o motivo da postagem?'), findsOneWidget);
  });

  testWidgets('Perdi: não avança da foto sem foto (erro na própria tela)',
      (tester) async {
    await abrir(tester);
    await avancar(tester);
    expect(find.text('Foto do pet'), findsOneWidget);
    expect(find.text('Obrigatória'), findsOneWidget);

    await avancar(tester);
    expect(find.text('A foto é obrigatória para "Perdi meu Pet".'),
        findsOneWidget);
    expect(find.text('Foto do pet'), findsOneWidget); // continua na etapa
  });

  testWidgets('Avistei: foto opcional e validação da etapa do pet',
      (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Avistei um pet solto'));
    await tester.pumpAndSettle();
    await avancar(tester);
    expect(find.text('Opcional'), findsOneWidget);

    await avancar(tester); // sem foto, mas é opcional
    expect(find.text('Sobre o pet'), findsOneWidget);
    expect(find.text('Nome do pet'), findsNothing); // nome só em Perdi

    await avancar(tester);
    expect(find.text('Escolha pelo menos uma cor.'), findsOneWidget);

    await tester.tap(find.text('Caramelo'));
    await tester.pumpAndSettle();
    expect(find.text('Escolha pelo menos uma cor.'), findsNothing);

    await avancar(tester);
    expect(find.text('Descreva o pet com pelo menos 10 caracteres.'),
        findsOneWidget);
    expect(find.text('0/10 mínimo'), findsOneWidget);
  });

  testWidgets('cor: no máximo 2 escolhidas', (tester) async {
    await abrir(tester);
    await avancar(tester); // foto
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avistei um pet solto'));
    await tester.pumpAndSettle();
    await avancar(tester);
    await avancar(tester);

    await tester.tap(find.text('Preto'));
    await tester.tap(find.text('Branco'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cinza')); // desabilitado
    await tester.pumpAndSettle();
    expect(find.text('até 2 · 2 escolhida(s)'), findsOneWidget);
  });
}

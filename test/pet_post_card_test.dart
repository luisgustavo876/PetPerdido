import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petperdido/widgets/pet_post_card.dart';
import 'helpers.dart';

void main() {
  Future<void> mostrar(WidgetTester tester, Widget card) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: ListView(children: [card]))));

  testWidgets('mostra nome, bairro, tempo e distância', (tester) async {
    final post = postDeTeste(
        eventAt: DateTime.now().subtract(const Duration(hours: 2)));
    await mostrar(tester, PetPostCard(post: post, distanciaKm: 1.24));

    expect(find.text('Pipoca'), findsOneWidget);
    expect(find.text('Centro, Itapetininga'), findsOneWidget);
    expect(find.text('há 2 h · a 1,2 km'), findsOneWidget);
    expect(find.text('Caramelo'), findsOneWidget);
  });

  testWidgets('post resolvido mostra a etiqueta RESOLVIDO', (tester) async {
    await mostrar(tester, PetPostCard(post: postDeTeste(resolvido: true)));
    expect(find.text('RESOLVIDO'), findsOneWidget);
  });

  testWidgets('sem distância, mostra só o tempo', (tester) async {
    final post = postDeTeste(
        eventAt: DateTime.now().subtract(const Duration(minutes: 5)));
    await mostrar(tester, PetPostCard(post: post));
    expect(find.text('há 5 min'), findsOneWidget);
  });
}

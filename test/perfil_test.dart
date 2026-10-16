import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petperdido/core/app_constants.dart';
import 'package:petperdido/screens/legal/legal_screens.dart';
import 'package:petperdido/services/user_service.dart';

void main() {
  group('Perfil.mascararCpf', () {
    test('mostra só os 6 dígitos do meio', () {
      expect(Perfil.mascararCpf('12345678909'), '***.456.789-**');
      expect(Perfil.mascararCpf('123.456.789-09'), '***.456.789-**');
    });

    test('CPF ausente ou inválido não vaza nada', () {
      expect(Perfil.mascararCpf(''), '***.***.***-**');
      expect(Perfil.mascararCpf('123'), '***.***.***-**');
    });
  });

  test('Perfil.fromMap com documento antigo usa valores padrão', () {
    final p = Perfil.fromMap({'name': 'Ana', 'email': 'a@example.com'});
    expect(p.pontos, 0);
    expect(p.alertasAtivos, isFalse);
    expect(p.raioKm, AppConstants.alertRadiusPadraoKm);
  });

  testWidgets('Política de Privacidade explica dados, finalidade e terceiros',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacidadeScreen()));
    expect(find.text('Política de Privacidade'), findsOneWidget);
    expect(find.text('Quais dados coletamos'), findsOneWidget);
    expect(find.textContaining('CPF e data de nascimento'), findsOneWidget);
    expect(find.textContaining('Localização aproximada'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Serviços de terceiros'), 200);
    expect(find.textContaining('Gemini'), findsOneWidget);
    expect(find.textContaining('Firebase'), findsWidgets);
  });

  testWidgets('Termos de Uso abrem', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TermosScreen()));
    expect(find.text('Termos de Uso'), findsOneWidget);
    expect(find.textContaining('16 anos'), findsOneWidget);
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petperdido/models/sighting_model.dart';

void main() {
  final avistamento = SightingModel(
    userId: 'u2',
    userName: 'João',
    address: 'Vila Barth, Itapetininga',
    lat: -23.59,
    lng: -48.053,
    notes: 'Correu para a praça.',
    createdAt: DateTime(2026, 10, 16, 9, 30),
  );

  test('toMap e fromMap preservam os dados (data como Timestamp)', () {
    final map = avistamento.toMap();
    expect(map['createdAt'], isA<Timestamp>());
    final copia = SightingModel.fromMap(map);
    expect(copia.userId, 'u2');
    expect(copia.address, 'Vila Barth, Itapetininga');
    expect(copia.lat, -23.59);
    expect(copia.notes, 'Correu para a praça.');
    expect(copia.createdAt, DateTime(2026, 10, 16, 9, 30));
  });

  test('sem coordenadas e sem foto (bairro digitado não encontrado)', () {
    final map = SightingModel(
      userId: 'u3',
      userName: 'Ana',
      address: 'Bairro Novo',
      createdAt: DateTime(2026, 10, 16),
    ).toMap();
    final copia = SightingModel.fromMap(map);
    expect(copia.lat, isNull);
    expect(copia.photoUrl, isNull);
  });

  test('createdAt ainda não confirmado pelo servidor não quebra', () {
    final map = avistamento.toMap()..['createdAt'] = null;
    expect(SightingModel.fromMap(map).createdAt, isA<DateTime>());
  });
}

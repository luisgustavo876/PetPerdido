import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petperdido/models/notificacao_model.dart';

void main() {
  test('alerta novo: texto completo, foto e post', () {
    final n = NotificacaoModel.fromMap('n1', {
      'title': '🚨 PERDIDO: Pipoca · cão caramelo',
      'body': '📍 Vila Barth · sumiu hoje às 09:00\nMédio · Labrador',
      'image': 'https://firebasestorage.googleapis.com/foto.jpg',
      'postId': 'p1',
      'type': 'perdi',
      'read': false,
      'createdAt': Timestamp.fromDate(DateTime(2026, 10, 16, 9)),
    });
    expect(n.titulo, startsWith('🚨 PERDIDO'));
    expect(n.corpo.split('\n'), hasLength(2));
    expect(n.imagem, 'https://firebasestorage.googleapis.com/foto.jpg');
    expect(n.postId, 'p1');
    expect(n.lida, isFalse);
    expect(n.createdAt, DateTime(2026, 10, 16, 9));
  });

  test('alerta antigo (sem foto) e foto que não é https ficam sem imagem', () {
    expect(NotificacaoModel.fromMap('a', {'title': 'x'}).imagem, isNull);
    expect(NotificacaoModel.fromMap('b', {'image': 'http://inseguro/x.jpg'}).imagem,
        isNull);
    expect(NotificacaoModel.fromMap('c', {'image': null}).imagem, isNull);
  });
}

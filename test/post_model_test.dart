import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petperdido/models/post_model.dart';

void main() {
  final post = PostModel(
    id: '123',
    userId: 'user1',
    userName: 'Maria',
    type: PostType.lost,
    petName: 'Pipoca',
    description: 'Cachorro caramelo de coleira azul.',
    tags: ['Cão'],
    lastSeenAddress: 'Centro, Itapetininga',
    latitude: -23.59,
    longitude: -48.05,
    createdAt: DateTime(2026, 10, 6, 14, 30),
    breed: 'SRD',
    species: 'Cão',
    size: 'Médio',
    sex: 'Macho',
    points: 0,
    helpersCount: 0,
    sightingsCount: 0,
    traits: ['Dócil'],
  );

  test('toMap e fromMap preservam os dados do post', () {
    final copia = PostModel.fromMap(post.toMap());

    expect(copia.id, post.id);
    expect(copia.type, PostType.lost);
    expect(copia.petName, 'Pipoca');
    expect(copia.latitude, -23.59);
    expect(copia.createdAt, post.createdAt);
    expect(copia.geohash, post.geohash);
    expect(copia.traits, ['Dócil']);
  });

  test('toMap salva createdAt como Timestamp', () {
    final createdAt = post.toMap()['createdAt'];
    expect(createdAt, isA<Timestamp>());
    expect((createdAt as Timestamp).toDate(), post.createdAt);
  });

  test('fromMap ainda aceita createdAt em texto (posts antigos)', () {
    final map = post.toMap()..['createdAt'] = '2026-10-06T14:30:00.000';
    expect(PostModel.fromMap(map).createdAt, DateTime(2026, 10, 6, 14, 30));
  });

  group('geohash', () {
    test('é calculado com precisão 9 e na ordem certa (lat, lng)', () {
      // Exemplo clássico de geohash: 57.64911, 10.40744 -> u4pruydqq...
      expect(PostModel.calcularGeohash(57.64911, 10.40744), 'u4pruydqq');
      expect(post.geohash.length, PostModel.geohashPrecision);
    });

    test('vai para o Firestore no toMap', () {
      expect(post.toMap()['geohash'], post.geohash);
    });

    test('documento sem geohash (post antigo) recebe o valor calculado', () {
      final map = post.toMap()..remove('geohash');
      final antigo = PostModel.fromMap(map);
      expect(antigo.geohash, PostModel.calcularGeohash(-23.59, -48.05));
    });

    test('copyWith recalcula quando a posição muda', () {
      final movido = post.copyWith(latitude: 57.64911, longitude: 10.40744);
      expect(movido.geohash, 'u4pruydqq');
      expect(post.copyWith(petName: 'Bob').geohash, post.geohash);
    });
  });

  group('cores e data do ocorrido (eventAt)', () {
    final comCores = post.copyWith(
      colors: ['Preto', 'Branco'],
      eventAt: DateTime(2026, 10, 5, 18, 0),
    );

    test('vão para o Firestore (eventAt como Timestamp)', () {
      final map = comCores.toMap();
      expect(map['colors'], ['Preto', 'Branco']);
      expect(map['eventAt'], isA<Timestamp>());
    });

    test('voltam iguais pelo fromMap', () {
      final copia = PostModel.fromMap(comCores.toMap());
      expect(copia.colors, ['Preto', 'Branco']);
      expect(copia.eventAt, DateTime(2026, 10, 5, 18, 0));
    });

    test('post antigo sem esses campos: sem cores e eventAt = createdAt', () {
      final map = post.toMap()
        ..remove('colors')
        ..remove('eventAt');
      final antigo = PostModel.fromMap(map);
      expect(antigo.colors, isEmpty);
      expect(antigo.eventAt, post.createdAt);
    });

    test('sem eventAt no construtor, vale o createdAt', () {
      expect(post.eventAt, post.createdAt);
    });
  });

  group('PostType', () {
    test('converte o valor salvo no Firestore', () {
      expect(PostType.fromValue('perdi'), PostType.lost);
      expect(PostType.fromValue('achei'), PostType.found);
      expect(PostType.fromValue('avistei'), PostType.sighted);
    });

    test('valor desconhecido retorna null, sem exceção', () {
      expect(PostType.fromValue('xyz'), isNull);
      expect(PostType.fromValue(null), isNull);
    });

    test('fromMap com tipo desconhecido lança FormatException', () {
      final map = post.toMap()..['type'] = 'xyz';
      expect(() => PostModel.fromMap(map), throwsFormatException);
    });
  });
}

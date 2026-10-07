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
    expect(copia.traits, ['Dócil']);
  });

  test('PostType converte o valor salvo no Firestore', () {
    expect(PostType.fromValue('perdi'), PostType.lost);
    expect(PostType.fromValue('achei'), PostType.found);
    expect(PostType.fromValue('avistei'), PostType.sighted);
  });
}

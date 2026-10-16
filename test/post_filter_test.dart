import 'package:flutter_test/flutter_test.dart';
import 'package:petperdido/models/post_filter.dart';
import 'package:petperdido/models/post_model.dart';

void main() {
  final agora = DateTime(2026, 10, 16, 12);

  PostModel post({
    String id = '1',
    PostType type = PostType.lost,
    String species = 'Cão',
    String size = 'Médio',
    List<String> colors = const ['Caramelo'],
    bool resolvido = false,
    Duration ha = const Duration(hours: 1),
  }) {
    return PostModel(
      id: id,
      userId: 'u',
      userName: 'n',
      type: type,
      petName: 'Pipoca',
      description: 'descrição longa o bastante',
      tags: const [],
      lastSeenAddress: 'Centro, Itapetininga',
      latitude: -23.59,
      longitude: -48.05,
      createdAt: agora.subtract(ha),
      isResolved: resolvido,
      breed: 'SRD',
      species: species,
      size: size,
      sex: 'Macho',
      colors: colors,
      points: 0,
      helpersCount: 0,
      sightingsCount: 0,
      traits: const [],
    );
  }

  test('sem filtros: aceita tudo, menos resolvidos', () {
    const f = PostFilter();
    expect(f.aceita(post(), agora: agora), isTrue);
    expect(f.aceita(post(resolvido: true), agora: agora), isFalse);
    expect(f.quantidadeAtivos, 0);
  });

  test('incluir resolvidos', () {
    const f = PostFilter(incluirResolvidos: true);
    expect(f.aceita(post(resolvido: true), agora: agora), isTrue);
  });

  test('tipo, espécie, porte e cor', () {
    final f = const PostFilter().copyWith(
      tipos: {PostType.found, PostType.sighted},
      especie: 'Gato',
      porte: 'Pequeno',
      cor: 'Preto',
    );
    expect(f.quantidadeAtivos, 4);
    final ok = post(
        type: PostType.found, species: 'Gato', size: 'Pequeno', colors: ['Preto']);
    expect(f.aceita(ok, agora: agora), isTrue);
    expect(f.aceita(post(type: PostType.lost, species: 'Gato', size: 'Pequeno', colors: ['Preto']), agora: agora), isFalse);
    expect(f.aceita(post(type: PostType.found, species: 'Cão', size: 'Pequeno', colors: ['Preto']), agora: agora), isFalse);
    expect(f.aceita(post(type: PostType.found, species: 'Gato', size: 'Grande', colors: ['Preto']), agora: agora), isFalse);
    expect(f.aceita(post(type: PostType.found, species: 'Gato', size: 'Pequeno', colors: ['Branco']), agora: agora), isFalse);
  });

  test('período usa a data do ocorrido', () {
    final f = const PostFilter(periodo: PeriodoFiltro.h24);
    expect(f.aceita(post(ha: const Duration(hours: 23)), agora: agora), isTrue);
    expect(f.aceita(post(ha: const Duration(hours: 25)), agora: agora), isFalse);
    final f7 = const PostFilter(periodo: PeriodoFiltro.d7);
    expect(f7.aceita(post(ha: const Duration(days: 6)), agora: agora), isTrue);
    expect(f7.aceita(post(ha: const Duration(days: 8)), agora: agora), isFalse);
  });

  test('só favoritos', () {
    const f = PostFilter(soFavoritos: true);
    expect(f.aceita(post(id: 'a'), agora: agora, favoritos: {'a'}), isTrue);
    expect(f.aceita(post(id: 'b'), agora: agora, favoritos: {'a'}), isFalse);
  });

  test('copyWith com null limpa o campo; sem passar, mantém', () {
    final f = const PostFilter(especie: 'Gato', cor: 'Preto');
    expect(f.copyWith(especie: null).especie, isNull);
    expect(f.copyWith(especie: null).cor, 'Preto');
    expect(f.copyWith(ordem: OrdemFeed.maisPerto).especie, 'Gato');
  });
}

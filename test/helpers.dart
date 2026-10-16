import 'package:petperdido/models/post_model.dart';

/// Post de exemplo para os testes, com valores padrão que podem ser trocados.
PostModel postDeTeste({
  String id = '1',
  String userId = 'u1',
  PostType type = PostType.lost,
  String petName = 'Pipoca',
  String species = 'Cão',
  String size = 'Médio',
  String breed = 'SRD',
  List<String> colors = const ['Caramelo'],
  List<String> traits = const [],
  String description = 'Cachorro dócil de coleira azul.',
  String endereco = 'Centro, Itapetininga',
  double lat = -23.59,
  double lng = -48.05,
  DateTime? eventAt,
  bool resolvido = false,
}) {
  final quando = eventAt ?? DateTime(2026, 10, 16, 12);
  return PostModel(
    id: id,
    userId: userId,
    userName: 'Maria',
    type: type,
    petName: petName,
    description: description,
    tags: [species, breed, size, ...colors],
    lastSeenAddress: endereco,
    latitude: lat,
    longitude: lng,
    createdAt: quando,
    eventAt: quando,
    isResolved: resolvido,
    breed: breed,
    species: species,
    size: size,
    sex: 'Macho',
    colors: colors,
    points: 0,
    helpersCount: 0,
    sightingsCount: 0,
    traits: traits,
  );
}

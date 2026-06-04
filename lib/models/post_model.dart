import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_constants.dart';

/// Enum representando os tipos de postagem.
enum PostType {
  lost(AppConstants.postTypeLost),
  found(AppConstants.postTypeFound),
  sighted(AppConstants.postTypeSighted);

  final String value;
  const PostType(this.value);

  static PostType fromValue(String value) {
    return PostType.values.firstWhere((e) => e.value == value);
  }

  String get label => AppConstants.postTypeLabels[value] ?? value;
}

/// Modelo de dados de uma Postagem.
/// Espelha a estrutura que será salva no Firestore com campos adicionais de alta fidelidade.
class PostModel {
  final String id;
  final String userId;
  final String userName;
  final PostType type;
  final String petName;
  final String description;
  final List<String> tags;
  final String lastSeenAddress;
  final double latitude;
  final double longitude;
  final String? photoUrl;
  final DateTime createdAt;
  final bool isResolved;

  // Novos campos do protótipo
  final String breed;
  final String species;
  final String size;
  final String sex;
  final int points;
  final int helpersCount;
  final int sightingsCount;
  final String? ownerAvatar;
  final List<String> traits;

  const PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.petName,
    required this.description,
    required this.tags,
    required this.lastSeenAddress,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    required this.createdAt,
    this.isResolved = false,
    required this.breed,
    required this.species,
    required this.size,
    required this.sex,
    required this.points,
    required this.helpersCount,
    required this.sightingsCount,
    this.ownerAvatar,
    required this.traits,
  });

  PostModel copyWith({
    String? id,
    String? userId,
    String? userName,
    PostType? type,
    String? petName,
    String? description,
    List<String>? tags,
    String? lastSeenAddress,
    double? latitude,
    double? longitude,
    String? photoUrl,
    DateTime? createdAt,
    bool? isResolved,
    String? breed,
    String? species,
    String? size,
    String? sex,
    int? points,
    int? helpersCount,
    int? sightingsCount,
    String? ownerAvatar,
    List<String>? traits,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      petName: petName ?? this.petName,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      lastSeenAddress: lastSeenAddress ?? this.lastSeenAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      isResolved: isResolved ?? this.isResolved,
      breed: breed ?? this.breed,
      species: species ?? this.species,
      size: size ?? this.size,
      sex: sex ?? this.sex,
      points: points ?? this.points,
      helpersCount: helpersCount ?? this.helpersCount,
      sightingsCount: sightingsCount ?? this.sightingsCount,
      ownerAvatar: ownerAvatar ?? this.ownerAvatar,
      traits: traits ?? this.traits,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'type': type.value,
      'petName': petName,
      'description': description,
      'tags': tags,
      'lastSeenAddress': lastSeenAddress,
      'latitude': latitude,
      'longitude': longitude,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'isResolved': isResolved,
      'breed': breed,
      'species': species,
      'size': size,
      'sex': sex,
      'points': points,
      'helpersCount': helpersCount,
      'sightingsCount': sightingsCount,
      'ownerAvatar': ownerAvatar,
      'traits': traits,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      type: PostType.fromValue(map['type'] as String),
      petName: map['petName'] as String,
      description: map['description'] as String,
      tags: List<String>.from(map['tags'] as List),
      lastSeenAddress: map['lastSeenAddress'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      photoUrl: map['photoUrl'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] as String),
      isResolved: map['isResolved'] as bool? ?? false,
      breed: map['breed'] as String? ?? 'Desconhecida',
      species: map['species'] as String? ?? 'Cão',
      size: map['size'] as String? ?? 'Médio',
      sex: map['sex'] as String? ?? 'Macho',
      points: map['points'] as int? ?? 0,
      helpersCount: map['helpersCount'] as int? ?? 0,
      sightingsCount: map['sightingsCount'] as int? ?? 0,
      ownerAvatar: map['ownerAvatar'] as String?,
      traits: List<String>.from(map['traits'] as List? ?? []),
    );
  }
}

/// Dados mockados para desenvolvimento da UI (baseados no protótipo HTML).
final List<PostModel> mockPosts = [
  PostModel(
    id: '1',
    userId: 'user1',
    userName: 'Carol Mendes',
    type: PostType.lost,
    petName: 'Laura',
    description:
        'Minha gatinha Siamesa desapareceu ontem à tarde na Vila Barth. Ela é dócil, mas pode estar assustada. Por favor, ajude a encontrá-la!',
    tags: ['Siamesa', 'Olhos Azuis', 'Creme', 'Dócil'],
    lastSeenAddress: 'Vila Barth, Itapetininga',
    latitude: -23.5897,
    longitude: -48.0533,
    photoUrl: 'assets/images/cat1.jpg',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    breed: 'Siamesa',
    species: 'Gato',
    size: 'Pequeno',
    sex: 'Fêmea',
    points: 150,
    helpersCount: 12,
    sightingsCount: 2,
    ownerAvatar: null,
    traits: ['Olhos azuis', 'Creme', 'Sem coleira'],
  ),
  PostModel(
    id: '2',
    userId: 'user2',
    userName: 'Danilo Ramos',
    type: PostType.sighted,
    petName: 'Rex',
    description:
        'Avistei este cachorro de porte médio com coleira vermelha correndo assustado perto do Jardim Marabá. Parece ser de raça misturada.',
    tags: ['Vira-lata', 'Preto/Marrom', 'Coleira Vermelha'],
    lastSeenAddress: 'Jardim Marabá, Itapetininga',
    latitude: -23.5950,
    longitude: -48.0600,
    photoUrl: 'assets/images/dog1.jpg',
    createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    breed: 'Sem Raça Definida',
    species: 'Cão',
    size: 'Médio',
    sex: 'Macho',
    points: 0,
    helpersCount: 4,
    sightingsCount: 1,
    ownerAvatar: null,
    traits: ['Preto/Marrom', 'Coleira vermelha'],
  ),
  PostModel(
    id: '3',
    userId: 'user3',
    userName: 'Ana Costa',
    type: PostType.found,
    petName: 'Sem nome (Pipoca)',
    description:
        'Encontrei este lindo cachorrinho Golden no Centro. Está bem cuidado e com coleira azul, super dócil. Está seguro comigo aguardando o tutor!',
    tags: ['Golden Retriever', 'Dourado', 'Coleira Azul'],
    lastSeenAddress: 'Centro, Itapetininga',
    latitude: -23.5880,
    longitude: -48.0510,
    photoUrl: 'assets/images/dog2.jpg',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    breed: 'Golden Retriever',
    species: 'Cão',
    size: 'Grande',
    sex: 'Macho',
    points: 0,
    helpersCount: 8,
    sightingsCount: 0,
    ownerAvatar: null,
    traits: ['Peludo', 'Dourado', 'Muito dócil'],
  ),
];

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
/// Espelha a estrutura que será salva no Firestore.
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
  });

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
      createdAt: DateTime.parse(map['createdAt'] as String),
      isResolved: map['isResolved'] as bool? ?? false,
    );
  }
}

/// Dados mockados para desenvolvimento da UI.
final List<PostModel> mockPosts = [
  PostModel(
    id: '1',
    userId: 'user1',
    userName: 'Carol',
    type: PostType.lost,
    petName: 'Laura',
    description:
        'Meu gato desapareceu ontem e não voltou para casa até agora. '
        'Costuma sair por pouco tempo, mas dessa vez está demorando bastante.',
    tags: ['Pelagem curta', 'Creme', 'Olhos azuis', 'Porte pequeno', 'Shi-tzu'],
    lastSeenAddress: 'Vila Barth, Itapetininga',
    latitude: -23.5897,
    longitude: -48.0533,
    photoUrl: 'assets/images/dog_lost.png',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  PostModel(
    id: '2',
    userId: 'user2',
    userName: 'Danilo',
    type: PostType.sighted,
    petName: 'Sem nome',
    description:
        'Vi esse cachorro há pouco sozinho no Jardim Marabá. '
        'Ele parecia perdido e está com coleira.',
    tags: ['Pelagem curta', 'Tricolor', 'Porte médio', 'Com coleira'],
    lastSeenAddress: 'Jardim Marabá, Itapetininga',
    latitude: -23.5950,
    longitude: -48.0600,
    photoUrl: 'assets/images/dog_sighted.png',
    createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
  ),
  PostModel(
    id: '3',
    userId: 'user3',
    userName: 'Ana',
    type: PostType.found,
    petName: 'Sem nome',
    description:
        'Encontrei esse cachorrinho hoje. '
        'Está bem tratado e com coleira, mas sem plaquinha.',
    tags: ['Branco', 'Porte médio', 'Bull Terrier', 'Com coleira'],
    lastSeenAddress: 'Centro, Itapetininga',
    latitude: -23.5880,
    longitude: -48.0510,
    photoUrl: 'assets/images/dog_found.png',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
];

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import '../core/app_constants.dart';

/// Enum representando os tipos de postagem.
enum PostType {
  lost(AppConstants.postTypeLost),
  found(AppConstants.postTypeFound),
  sighted(AppConstants.postTypeSighted);

  final String value;
  const PostType(this.value);

  /// Converte o valor salvo no Firestore. Retorna null se for desconhecido
  /// (em vez de lançar exceção).
  static PostType? fromValue(String? value) {
    for (final tipo in PostType.values) {
      if (tipo.value == value) return tipo;
    }
    return null;
  }

  String get label => AppConstants.postTypeLabels[value] ?? value;
}

/// Modelo de dados de uma Postagem.
/// Espelha a estrutura que será salva no Firestore com campos adicionais de alta fidelidade.
class PostModel {
  /// Precisão do geohash salvo (9 caracteres ≈ 5 m x 5 m).
  static const int geohashPrecision = 9;

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

  /// Geohash da posição — usado para buscar posts por região.
  /// Se não for informado, é calculado a partir de [latitude]/[longitude].
  final String geohash;
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

  PostModel({
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
    String? geohash,
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
  }) : geohash = geohash ?? calcularGeohash(latitude, longitude);

  /// Geohash de uma coordenada. Atenção: o GeoHasher recebe longitude primeiro.
  static String calcularGeohash(double latitude, double longitude) =>
      GeoHasher().encode(longitude, latitude, precision: geohashPrecision);

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
    String? geohash,
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
    // Se a posição mudou e nenhum geohash foi passado, recalcula (null).
    final mudouPosicao = latitude != null || longitude != null;
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
      geohash: geohash ?? (mudouPosicao ? null : this.geohash),
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
      'geohash': geohash,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
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

  /// Cria a partir de um documento do Firestore.
  /// Lança [FormatException] se faltar um campo essencial ou o tipo for
  /// desconhecido — o PostService ignora esses documentos.
  factory PostModel.fromMap(Map<String, dynamic> map) {
    final type = PostType.fromValue(map['type'] as String?);
    if (type == null) {
      throw FormatException('Tipo de post desconhecido: ${map['type']}');
    }

    final rawCreatedAt = map['createdAt'];
    final DateTime createdAt;
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.parse(rawCreatedAt); // posts antigos
    } else {
      throw const FormatException('createdAt ausente ou inválido');
    }

    return PostModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      type: type,
      petName: map['petName'] as String,
      description: map['description'] as String,
      tags: List<String>.from(map['tags'] as List? ?? []),
      lastSeenAddress: map['lastSeenAddress'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      geohash: map['geohash'] as String?, // posts antigos não têm
      photoUrl: map['photoUrl'] as String?,
      createdAt: createdAt,
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

import 'package:cloud_firestore/cloud_firestore.dart';

/// Avistamento ("Eu vi este pet") em posts/{postId}/sightings/{userId}.
///
/// O id do documento é o uid de quem viu: cada pessoa registra no máximo
/// um avistamento por post. Só bairro e coordenadas arredondadas (~100 m).
class SightingModel {
  final String userId;
  final String userName;
  final String address;
  final double? lat;
  final double? lng;
  final String notes;
  final String? photoUrl;
  final DateTime createdAt;

  const SightingModel({
    required this.userId,
    required this.userName,
    required this.address,
    this.lat,
    this.lng,
    this.notes = '',
    this.photoUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'address': address,
        'lat': lat,
        'lng': lng,
        'notes': notes,
        'photoUrl': photoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory SightingModel.fromMap(Map<String, dynamic> map) {
    final criado = map['createdAt'];
    return SightingModel(
      userId: map['userId'] as String,
      userName: map['userName'] as String? ?? 'Usuário',
      address: map['address'] as String? ?? '',
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      notes: map['notes'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      // Enquanto o servidor não confirma, um serverTimestamp chega nulo.
      createdAt: criado is Timestamp ? criado.toDate() : DateTime.now(),
    );
  }
}

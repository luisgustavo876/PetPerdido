import 'package:cloud_firestore/cloud_firestore.dart';

/// Avistamento ("Eu vi este pet") em posts/{postId}/sightings/{userId}.
///
/// O id do documento é o uid de quem viu: cada pessoa registra no máximo
/// um avistamento por post. Só bairro e coordenadas arredondadas (~100 m).
class SightingModel {
  /// Mínimo de caracteres da descrição (o mesmo valor está no firestore.rules).
  static const minDescricao = 10;

  /// O que falta para o avistamento poder ser registrado, ou null se está
  /// tudo certo. [bairroGenerico] é o texto que não vale como bairro
  /// ("Localização atual"). Função pura.
  static String? oQueFalta({
    required String bairro,
    required String descricao,
    String bairroGenerico = '',
  }) {
    final b = bairro.trim();
    final faltaBairro =
        b.isEmpty || b.toLowerCase() == bairroGenerico.toLowerCase();
    final faltam = descricao.trim().length;
    final faltaDescricao = faltam < minDescricao;
    final textoDescricao = faltam == 0
        ? 'descreva o que você viu (mínimo de $minDescricao caracteres)'
        : 'a descrição precisa de mais ${minDescricao - faltam} '
            '${minDescricao - faltam == 1 ? 'caractere' : 'caracteres'}';
    if (faltaBairro && faltaDescricao) {
      return 'Falta: informar o bairro e $textoDescricao.';
    }
    if (faltaBairro) return 'Falta: informar o bairro onde você viu o pet.';
    if (faltaDescricao) return 'Falta: $textoDescricao.';
    return null;
  }

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

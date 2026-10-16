import 'package:cloud_firestore/cloud_firestore.dart';

/// Alerta recebido em users/{uid}/notifications/{id}.
/// Criado pela Cloud Function quando sai um post perto do usuário.
class NotificacaoModel {
  final String id;
  final String titulo;
  final String corpo;
  final String? postId;
  final String tipo;
  final bool lida;
  final DateTime createdAt;

  const NotificacaoModel({
    required this.id,
    required this.titulo,
    required this.corpo,
    this.postId,
    required this.tipo,
    required this.lida,
    required this.createdAt,
  });

  factory NotificacaoModel.fromMap(String id, Map<String, dynamic> map) {
    final criada = map['createdAt'];
    return NotificacaoModel(
      id: id,
      titulo: map['title'] as String? ?? 'Alerta',
      corpo: map['body'] as String? ?? '',
      postId: map['postId'] as String?,
      tipo: map['type'] as String? ?? '',
      lida: map['read'] as bool? ?? false,
      createdAt: criada is Timestamp ? criada.toDate() : DateTime.now(),
    );
  }
}

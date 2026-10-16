import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';

class PostService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'posts';

  /// Quantos posts recentes o app carrega. Os filtros (tipo, espécie, período
  /// etc.) são aplicados no app, para não precisar de índices compostos.
  static const limiteRecentes = 100;

  static Query<Map<String, dynamic>> get _recentes => _db
      .collection(_col)
      .orderBy('createdAt', descending: true)
      .limit(limiteRecentes);

  /// Converte os documentos, ignorando os inválidos (com aviso no console)
  /// em vez de derrubar a lista inteira.
  static List<PostModel> _converter(QuerySnapshot<Map<String, dynamic>> snap) {
    final posts = <PostModel>[];
    for (final doc in snap.docs) {
      try {
        posts.add(PostModel.fromMap({...doc.data(), 'id': doc.id}));
      } catch (e) {
        debugPrint('PostService: post ${doc.id} ignorado (inválido): $e');
      }
    }
    return posts;
  }

  /// Últimos [limiteRecentes] posts em tempo real, mais recentes primeiro.
  static Stream<List<PostModel>> postsStream() =>
      _recentes.snapshots().map(_converter);

  /// Últimos [limiteRecentes] posts, uma única leitura (sem tempo real).
  static Future<List<PostModel>> postsRecentes() async =>
      _converter(await _recentes.get());

  static Future<void> createPost(PostModel post) async {
    await _db.collection(_col).doc(post.id).set(post.toMap());
  }

  static Future<void> incrementSighting(String postId) async {
    await _db.collection(_col).doc(postId).update({
      'sightingsCount': FieldValue.increment(1),
      'helpersCount': FieldValue.increment(1),
    });
  }
}

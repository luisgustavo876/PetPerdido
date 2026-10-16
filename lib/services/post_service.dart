import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../models/sighting_model.dart';
import 'storage_service.dart';

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

  /// Um post pelo id (ex.: ao abrir uma notificação). Null se não existir.
  static Future<PostModel?> buscarPost(String id) async {
    final snap = await _db.collection(_col).doc(id).get();
    final dados = snap.data();
    if (dados == null) return null;
    try {
      return PostModel.fromMap({...dados, 'id': snap.id});
    } catch (_) {
      return null;
    }
  }

  static Future<void> createPost(PostModel post) async {
    await _db.collection(_col).doc(post.id).set(post.toMap());
  }

  // ---------------------------------------------------------------------------
  // Avistamentos (posts/{id}/sightings/{uid})
  // ---------------------------------------------------------------------------

  static CollectionReference<Map<String, dynamic>> _avistamentos(
          String postId) =>
      _db.collection(_col).doc(postId).collection('sightings');

  /// Avistamentos do post em tempo real, mais recentes primeiro.
  static Stream<List<SightingModel>> avistamentosStream(String postId) {
    return _avistamentos(postId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => [
              for (final doc in snap.docs)
                SightingModel.fromMap({...doc.data(), 'userId': doc.id}),
            ]);
  }

  /// Registra o avistamento e soma +1 nos contadores do post, juntos (batch).
  /// O documento usa o uid como id: as regras impedem um segundo registro.
  static Future<void> registrarAvistamento(
      String postId, SightingModel avistamento) async {
    final batch = _db.batch()
      ..set(_avistamentos(postId).doc(avistamento.userId), avistamento.toMap())
      ..update(_db.collection(_col).doc(postId), {
        'sightingsCount': FieldValue.increment(1),
        'helpersCount': FieldValue.increment(1),
      });
    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Ações do autor
  // ---------------------------------------------------------------------------

  static Future<void> marcarResolvido(String postId) =>
      _db.collection(_col).doc(postId).update({'isResolved': true});

  /// Exclui o post, os avistamentos dele e as fotos no Storage.
  static Future<void> excluirPost(PostModel post) async {
    final avistamentos = await _avistamentos(post.id).get();
    final fotos = <String>[
      if (post.photoUrl != null) post.photoUrl!,
      for (final doc in avistamentos.docs)
        if (doc.data()['photoUrl'] is String) doc.data()['photoUrl'] as String,
    ];

    final batch = _db.batch();
    for (final doc in avistamentos.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection(_col).doc(post.id));
    await batch.commit();

    // Fotos por último: se alguma falhar, o post já foi removido.
    for (final url in fotos) {
      await StorageService.apagarPorUrl(url);
    }
  }
}

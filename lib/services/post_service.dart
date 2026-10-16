import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';

class PostService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'posts';

  /// Posts mais recentes primeiro. Documentos inválidos são ignorados
  /// (com aviso no console) em vez de derrubar a lista inteira.
  static Stream<List<PostModel>> postsStream() {
    return _db
        .collection(_col)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) {
      final posts = <PostModel>[];
      for (final doc in snap.docs) {
        try {
          posts.add(PostModel.fromMap({...doc.data(), 'id': doc.id}));
        } catch (e) {
          debugPrint('PostService: post ${doc.id} ignorado (inválido): $e');
        }
      }
      return posts;
    });
  }

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

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'posts';

  static Stream<List<PostModel>> postsStream() {
    return _db
        .collection(_col)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              return PostModel.fromMap({...doc.data(), 'id': doc.id});
            }).toList());
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

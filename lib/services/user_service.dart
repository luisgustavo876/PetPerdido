import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

/// Dados do usuário logado em users/{uid}.
class UserService {
  static final _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>>? get _meuDoc {
    final uid = AuthService.currentUser?.uid;
    return uid == null ? null : _db.collection('users').doc(uid);
  }

  /// IDs dos posts favoritados (leitura única).
  static Future<Set<String>> favoritos() async {
    final doc = _meuDoc;
    if (doc == null) return {};
    final snap = await doc.get();
    return Set<String>.from(snap.data()?['favorites'] as List? ?? const []);
  }

  /// Favorita ou desfavorita um post (arrayUnion / arrayRemove).
  static Future<void> definirFavorito(String postId, bool favorito) async {
    final doc = _meuDoc;
    if (doc == null) return;
    await doc.set({
      'favorites': favorito
          ? FieldValue.arrayUnion([postId])
          : FieldValue.arrayRemove([postId]),
    }, SetOptions(merge: true));
  }
}

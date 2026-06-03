import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await credential.user?.updateDisplayName(name.trim());

    await _db.collection('users').doc(credential.user!.uid).set({
      'id': credential.user!.uid,
      'name': name.trim(),
      'email': email.trim(),
      'points': 320,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static String get currentUserName =>
      currentUser?.displayName ?? currentUser?.email ?? 'Usuário';
}

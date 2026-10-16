import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'auth_service.dart';
import 'post_service.dart';
import 'storage_service.dart';

/// Erro ao excluir a conta, com mensagem pronta para o usuário.
class ContaException implements Exception {
  final String mensagem;
  const ContaException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// "Excluir minha conta" (LGPD): apaga os dados do usuário e a conta.
class ContaService {
  static final _db = FirebaseFirestore.instance;

  /// Pede a senha de novo (reautenticação) e apaga, nesta ordem:
  /// posts do usuário (com avistamentos e fotos), avistamentos que ele fez em
  /// outros posts, as mensagens dele e as conversas, as subcoleções e o
  /// documento users/{uid} e, por fim, o usuário do Firebase Auth.
  /// [etapa] recebe um texto curto para mostrar o andamento.
  static Future<void> excluirConta(String senha,
      {void Function(String)? etapa}) async {
    final user = AuthService.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const ContaException('Entre na sua conta.');
    }

    try {
      await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: senha));
    } on FirebaseAuthException catch (e) {
      throw ContaException(switch (e.code) {
        'wrong-password' || 'invalid-credential' => 'Senha incorreta.',
        'too-many-requests' => 'Muitas tentativas. Tente mais tarde.',
        'network-request-failed' => 'Sem conexão com a internet.',
        _ => 'Não foi possível confirmar sua senha.',
      });
    }

    final uid = user.uid;
    final meuDoc = _db.collection('users').doc(uid);
    try {
      etapa?.call('Apagando seus posts...');
      for (final post in await PostService.postsDoAutor(uid)) {
        await PostService.excluirPost(post);
      }

      // Os avistamentos ficam registrados no histórico de pontos (euvi_<id>).
      etapa?.call('Apagando seus avistamentos...');
      final historico = await meuDoc.collection('pointsLog').get();
      for (final doc in historico.docs) {
        if (!doc.id.startsWith('euvi_')) continue;
        final postId = doc.id.substring('euvi_'.length);
        final ref = _db.doc('posts/$postId/sightings/$uid');
        final avistamento = await ref.get();
        final foto = avistamento.data()?['photoUrl'];
        if (avistamento.exists) await ref.delete();
        if (foto is String) await StorageService.apagarPorUrl(foto);
      }

      etapa?.call('Apagando suas conversas...');
      final chats = await _db
          .collection('chats')
          .where('participants', arrayContains: uid)
          .get();
      for (final chat in chats.docs) {
        final minhas = await chat.reference
            .collection('messages')
            .where('senderId', isEqualTo: uid)
            .get();
        for (final m in minhas.docs) {
          final foto = m.data()['photoUrl'];
          if (foto is String) await StorageService.apagarPorUrl(foto);
          await m.reference.delete();
        }
        // Sem o documento da conversa, as mensagens da outra pessoa ficam
        // inacessíveis e o TTL apaga depois.
        await chat.reference.delete();
      }

      etapa?.call('Apagando seu perfil...');
      for (final sub in ['notifications', 'pointsLog', 'redemptions']) {
        final docs = await meuDoc.collection(sub).get();
        for (final d in docs.docs) {
          await d.reference.delete();
        }
      }
      await meuDoc.delete();

      etapa?.call('Apagando sua conta...');
      await user.delete();
    } on ContaException {
      rethrow;
    } catch (e) {
      debugPrint('ContaService: falha ao excluir: $e');
      throw const ContaException(
          'Não foi possível concluir a exclusão. Confira a internet e tente de novo — '
          'o que já foi apagado não volta, e o restante será apagado na nova tentativa.');
    }
  }
}

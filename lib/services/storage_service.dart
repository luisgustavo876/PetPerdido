import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:image_picker/image_picker.dart';

/// Serviço responsável pelos arquivos no Firebase Storage.
class StorageService {
  static final _storage = FirebaseStorage.instance;

  /// Envia [image] para [caminho] e devolve a URL pública de download.
  static Future<String> _enviar(XFile image, String caminho) async {
    final bytes = await image.readAsBytes();
    final ref = _storage.ref().child(caminho);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Foto de um post: posts/{postId}/foto.jpg. Lança exceção se falhar.
  static Future<String> uploadPostImage(XFile image, String postId) =>
      _enviar(image, 'posts/$postId/foto.jpg');

  /// Foto de um avistamento: posts/{postId}/avistamento_{uid}.jpg.
  static Future<String> uploadSightingImage(
          XFile image, String postId, String uid) =>
      _enviar(image, 'posts/$postId/avistamento_$uid.jpg');

  /// Apaga um arquivo pela URL de download. Não lança erro (o arquivo pode
  /// já não existir); só registra no console.
  static Future<void> apagarPorUrl(String url) async {
    if (!url.startsWith('http')) return;
    try {
      await _storage.refFromURL(url).delete();
    } catch (e) {
      debugPrint('StorageService: não apagou $url: $e');
    }
  }
}

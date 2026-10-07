import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Serviço responsável pelo upload de arquivos no Firebase Storage.
class StorageService {
  static final _storage = FirebaseStorage.instance;

  /// Faz upload da foto de um post para o Firebase Storage.
  /// Retorna a URL pública de download. Lança exceção se o upload falhar.
  /// [image] — arquivo selecionado pelo ImagePicker
  /// [postId] — ID único do post (usado como nome da pasta)
  static Future<String> uploadPostImage(XFile image, String postId) async {
    final bytes = await image.readAsBytes();
    final ref = _storage.ref().child('posts/$postId/foto.jpg');

    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}

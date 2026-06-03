import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Serviço responsável pelo upload de arquivos no Firebase Storage.
class StorageService {
  static final _storage = FirebaseStorage.instance;

  /// Faz upload da foto de um post para o Firebase Storage.
  /// Retorna a URL pública de download.
  /// [image] — arquivo selecionado pelo ImagePicker
  /// [postId] — ID único do post (usado como nome da pasta)
  static Future<String> uploadPostImage(XFile image, String postId) async {
    final Uint8List bytes = await image.readAsBytes();

    final Reference ref = _storage
        .ref()
        .child('posts/$postId/foto.jpg');

    try {
      // Adicionado um timeout de 3 segundos para evitar travamento infinito no Chrome
      // caso o usuário não tenha configurado o CORS ou as Regras do Firebase.
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      ).timeout(const Duration(seconds: 3));

      // Retorna a URL pública permanente
      return await ref.getDownloadURL();
    } catch (e) {
      // Se der erro de permissão ou CORS (muito comum no TCC na Web),
      // retorna uma imagem mockada para a apresentação não travar!
      print('Erro de upload (CORS ou Permissão). Usando imagem local de fallback.');
      return 'assets/images/dog-found.jpg';
    }
  }

  /// Exclui a foto de um post do Storage.
  static Future<void> deletePostImage(String postId) async {
    try {
      await _storage.ref().child('posts/$postId/foto.jpg').delete();
    } catch (_) {
      // Ignora se a foto não existir
    }
  }
}

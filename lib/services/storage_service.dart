import 'dart:math' show max;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'
    show Uint8List, compute, debugPrint;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../core/app_constants.dart';

/// Serviço responsável pelos arquivos no Firebase Storage.
class StorageService {
  static final _storage = FirebaseStorage.instance;

  /// Bytes prontos para enviar: foto inteira (sem recorte), no máximo
  /// [AppConstants.fotoMaxPixels] no lado maior e abaixo de 5 MB.
  static Future<Uint8List> bytesParaEnvio(XFile image) async =>
      compute(prepararFoto, await image.readAsBytes());

  /// Envia [image] para [caminho] e devolve a URL pública de download.
  static Future<String> _enviar(XFile image, String caminho) async {
    final bytes = await bytesParaEnvio(image);
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

/// Prepara a foto para o upload, sem recortar e mantendo a proporção:
/// - JPEG que já está dentro do tamanho e abaixo de 5 MB vai como está
///   (não recomprime, para não perder nitidez);
/// - senão, aplica a rotação do EXIF, reduz o lado maior para
///   [AppConstants.fotoMaxPixels] e grava JPEG qualidade
///   [AppConstants.fotoQualidade] (baixando a qualidade só se passar de 5 MB).
/// Se não conseguir ler a imagem, devolve a original. Função pura.
Uint8List prepararFoto(Uint8List original) {
  const maximo = AppConstants.fotoMaxPixels;
  const limite = AppConstants.fotoMaxBytes;

  final ehJpeg =
      original.length > 2 && original[0] == 0xFF && original[1] == 0xD8;
  final info = img.findDecoderForData(original)?.startDecode(original);
  if (ehJpeg &&
      info != null &&
      max(info.width, info.height) <= maximo &&
      original.length < limite) {
    return original;
  }

  final lida = img.decodeImage(original);
  if (lida == null) return original;
  final imagem = img.bakeOrientation(lida);

  final reduzida = max(imagem.width, imagem.height) <= maximo
      ? imagem
      : img.copyResize(
          imagem,
          width: imagem.width >= imagem.height ? maximo : null,
          height: imagem.height > imagem.width ? maximo : null,
          interpolation: img.Interpolation.average,
        );

  var qualidade = AppConstants.fotoQualidade;
  var jpeg = img.encodeJpg(reduzida, quality: qualidade);
  while (jpeg.length >= limite && qualidade > 40) {
    qualidade -= 15;
    jpeg = img.encodeJpg(reduzida, quality: qualidade);
  }
  return Uint8List.fromList(jpeg);
}

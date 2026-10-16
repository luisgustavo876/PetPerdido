import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_colors.dart';

/// Pergunta de onde vem a foto ("Tirar foto" só fora da Web, ou
/// "Escolher da galeria") e abre o seletor. Retorna null se cancelar.
/// Lança exceção se a câmera/galeria não abrir (ex.: permissão negada).
class SeletorImagem {
  SeletorImagem._();

  static Future<XFile?> escolher(BuildContext context) async {
    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined,
                      color: AppColors.primary),
                  title: const Text('Tirar foto'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: const Text('Escolher da galeria'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (origem == null) return null;
    return ImagePicker().pickImage(
      source: origem,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
  }
}

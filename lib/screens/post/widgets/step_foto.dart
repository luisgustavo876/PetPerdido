import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/app_colors.dart';
import '../../../models/post_model.dart';
import '../post_draft.dart';
import 'post_form_ui.dart';

/// Etapa 2 — Foto do pet (obrigatória em Perdi e Achei).
class StepFoto extends StatelessWidget {
  final PostDraft draft;
  final VoidCallback onChanged;

  const StepFoto({super.key, required this.draft, required this.onChanged});

  String get _subtitulo => switch (draft.type) {
        PostType.lost => 'Uma foto nítida ajuda muito quem pode ter visto seu pet.',
        PostType.found => 'Com a foto, o tutor reconhece o pet mais rápido.',
        PostType.sighted => 'Se conseguiu tirar uma foto, ela ajuda bastante.',
      };

  /// Pergunta de onde vem a foto (câmera só fora da Web) e abre o seletor.
  Future<void> _escolherFoto(BuildContext context) async {
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
    if (origem == null) return;

    try {
      final imagem = await ImagePicker().pickImage(
        source: origem,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (imagem == null) return;
      draft.imageFile = imagem;
      draft.imageBytes = await imagem.readAsBytes();
      onChanged();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível abrir a câmera ou a galeria.')),
      );
    }
  }

  void _remover() {
    draft.imageFile = null;
    draft.imageBytes = null;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final bytes = draft.imageBytes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepTitulo(titulo: 'Foto do pet', subtitulo: _subtitulo),
        RotuloSecao(
          'Foto',
          complemento: EtiquetaObrigatoria(obrigatoria: draft.fotoObrigatoria),
        ),
        AspectRatio(
          aspectRatio: 4 / 3,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: bytes == null
                ? _areaVazia(context)
                : ClipRRect(
                    key: ValueKey(bytes.hashCode),
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(bytes,
                        fit: BoxFit.cover, width: double.infinity),
                  ),
          ),
        ),
        if (bytes != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _escolherFoto(context),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Trocar foto'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  onPressed: _remover,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    minimumSize: const Size(0, 52),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remover'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _areaVazia(BuildContext context) {
    return InkWell(
      key: const ValueKey('vazia'),
      borderRadius: BorderRadius.circular(16),
      onTap: () => _escolherFoto(context),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_a_photo_outlined,
                  size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Toque para adicionar uma foto',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              kIsWeb ? 'Escolha uma imagem do computador' : 'Câmera ou galeria',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

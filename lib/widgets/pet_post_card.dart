import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/formatters.dart';
import '../core/post_type_style.dart';
import '../models/post_model.dart';
import 'pet_image.dart';

/// Card de um post no feed (também usado na prévia do criar post).
class PetPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;

  /// Distância até o usuário, quando conhecida ("a 1,2 km").
  final double? distanciaKm;

  /// Foto ainda não enviada (prévia do criar post). Tem prioridade sobre
  /// a URL do post.
  final Uint8List? fotoLocal;

  const PetPostCard({
    super.key,
    required this.post,
    this.onTap,
    this.distanciaKm,
    this.fotoLocal,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imagem(),
            _conteudo(),
          ],
        ),
      ),
    );
  }

  Widget _imagem() {
    return Stack(
      children: [
        Container(
          height: 208,
          width: double.infinity,
          color: AppColors.background,
          child: fotoLocal != null
              ? Image.memory(fotoLocal!, fit: BoxFit.cover)
              : PetImage(url: post.photoUrl, iconSize: 64),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Row(
            children: [
              _pilula(post.type.label.toUpperCase(), post.type.color),
              if (post.isResolved) ...[
                const SizedBox(width: 8),
                _pilula('RESOLVIDO', AppColors.tagFound),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _pilula(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _conteudo() {
    final nome = post.petName.isNotEmpty && post.petName != 'Sem nome'
        ? post.petName
        : 'Pet sem nome';
    final quando = Formatters.tempoRelativo(post.eventAt, DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nome,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  post.lastSeenAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // "há 2 h · a 1,2 km"
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                [
                  quando,
                  if (distanciaKm != null) Formatters.distancia(distanciaKm!),
                ].join(' · '),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tag(post.species),
              _tag(post.breed),
              for (final cor in post.colors) _tag(cor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

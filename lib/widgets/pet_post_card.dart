import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../models/post_model.dart';
import '../screens/chat/chat_screen.dart';

class PetPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;

  const PetPostCard({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final statusColor = _statusColor(post.type);

    return Stack(
      children: [
        Container(
          height: 210,
          width: double.infinity,
          color: AppColors.background,
          child: post.photoUrl != null
            ? _renderImage(post.photoUrl!)
            : const Center(
                child: Icon(Icons.pets, size: 64, color: AppColors.textTertiary),
              ),
        ),
        // Status pill — canto superior esquerdo
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              post.type.label.toUpperCase(),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        // Recompensa — canto superior direito
        if (post.points > 0)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${post.points} pts',
                    style: GoogleFonts.inter(
                      color: AppColors.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome do pet
          Text(
            post.petName.isNotEmpty && post.petName != 'Sem nome'
                ? post.petName
                : 'Pet sem nome',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          // Localização
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  post.lastSeenAddress,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Footer: tags + ação
          Row(
            children: [
              _tag(post.species),
              const SizedBox(width: 6),
              _tag(post.breed),
              const Spacer(),
              // Botão de chat
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(post: post),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(
                        'Conversar',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _statusColor(PostType type) {
    switch (type) {
      case PostType.lost:
        return AppColors.tagLost;
      case PostType.found:
        return AppColors.tagFound;
      case PostType.sighted:
        return AppColors.tagSighted;
    }
  }

  /// Exibe imagem de rede (Firebase Storage) ou asset local.
  Widget _renderImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        },
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image, color: AppColors.textTertiary, size: 48)),
      );
    }
    return Image.asset(url, fit: BoxFit.cover);
  }
}

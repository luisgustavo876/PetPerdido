import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/post_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Card de postagem que aparece no Feed e no Mapa do PetPerdido.
///
/// Exibe foto do pet, tipo do post (badge colorido),
/// nome, descrição resumida, tags e localização.
class PetPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback? onChatTap;

  const PetPostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 8),
                  _buildLocation(),
                  const SizedBox(height: 6),
                  Text(
                    post.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurface,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTags(),
                  const SizedBox(height: 10),
                  _buildChatButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (post.photoUrl == null) return _imagePlaceholder();

    final isAsset = post.photoUrl!.startsWith('assets/');

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: isAsset
          ? Image.asset(
              post.photoUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          : CachedNetworkImage(
              imageUrl: post.photoUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => _imagePlaceholder(),
              errorWidget: (_, __, ___) => _imagePlaceholder(),
            ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: AppColors.divider,
      child: const Icon(Icons.pets, size: 60, color: AppColors.textSecondary),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            post.userName.isNotEmpty ? post.userName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          post.userName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(width: 8),
        _buildTypeBadge(),
        const Spacer(),
        Text(
          _timeAgo(post.createdAt),
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: _badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        // ignore: deprecated_member_use
        border: Border.all(color: _badgeColor.withOpacity(0.4)),
      ),
      child: Text(
        post.type.label,
        style: TextStyle(
          color: _badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLocation() {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined,
            size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            post.lastSeenAddress,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: post.tags
          .take(5)
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                tag,
                style: const TextStyle(fontSize: 11, color: AppColors.onSurface),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildChatButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onChatTap,
      icon: const Icon(Icons.chat_bubble_outline, size: 16),
      label: const Text('Iniciar Chat'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Color get _badgeColor {
    switch (post.type) {
      case PostType.lost:
        return AppColors.tagLost;
      case PostType.found:
        return AppColors.tagFound;
      case PostType.sighted:
        return AppColors.tagSighted;
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    return '${diff.inDays}d atrás';
  }
}

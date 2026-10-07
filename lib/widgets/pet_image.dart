import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Imagem de pet que funciona tanto com URL do Firebase Storage (https)
/// quanto com asset local. Se a imagem não existir ou falhar, mostra um ícone.
class PetImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double iconSize;

  const PetImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.iconSize = 48,
  });

  /// Versão "ImageProvider" para usar em CircleAvatar.backgroundImage.
  static ImageProvider? provider(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return CachedNetworkImageProvider(url);
    return AssetImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: Icon(Icons.pets, size: iconSize, color: AppColors.textTertiary),
    );

    if (url == null || url!.isEmpty) return placeholder;

    if (url!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url!,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (_, __, ___) => placeholder,
      );
    }

    return Image.asset(
      url!,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}

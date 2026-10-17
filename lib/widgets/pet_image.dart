import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Imagem de pet que funciona tanto com URL do Firebase Storage (https)
/// quanto com asset local. Se a imagem não existir ou falhar, mostra um ícone.
///
/// Na Web, a imagem é baixada pelo navegador e, se o bucket não liberar CORS,
/// cai para um elemento <img> comum (WebHtmlElementStrategy.fallback) — assim
/// as fotos aparecem mesmo antes de o cors.json ser aplicado no Storage.
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
    if (url.startsWith('http')) {
      if (kIsWeb) {
        return NetworkImage(url,
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback);
      }
      return CachedNetworkImageProvider(url);
    }
    return AssetImage(url);
  }

  /// Registra no console (só em modo debug) por que a imagem não carregou.
  static void _logarErro(String url, Object erro) {
    assert(() {
      debugPrint('PetImage: falha ao carregar $url: $erro');
      return true;
    }());
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: Icon(Icons.pets, size: iconSize, color: AppColors.textTertiary),
    );

    if (url == null || url!.isEmpty) return placeholder;

    if (url!.startsWith('http')) {
      if (kIsWeb) {
        return Image.network(
          url!,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          loadingBuilder: (_, child, progresso) => progresso == null
              ? child
              : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorBuilder: (_, erro, __) {
            _logarErro(url!, erro);
            return placeholder;
          },
        );
      }
      return CachedNetworkImage(
        imageUrl: url!,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (_, __, erro) {
          _logarErro(url!, erro);
          return placeholder;
        },
      );
    }

    return Image.asset(
      url!,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, erro, __) {
        _logarErro(url!, erro);
        return placeholder;
      },
    );
  }
}

import 'dart:ui' show ImageFilter;
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

  /// Altura da imagem. null = altura pela proporção original da foto.
  final double? height;

  /// Mostra a foto inteira (BoxFit.contain) sobre uma versão desfocada dela
  /// mesma, para preencher o espaço sem recortar o pet.
  final bool semCorte;

  const PetImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.iconSize = 48,
    this.height = double.infinity,
    this.semCorte = false,
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

    if (semCorte) {
      return ImagemSemCorte(
        imagem: (fit, {required bool fundo}) =>
            _imagem(fit, placeholder, fundo: fundo),
      );
    }
    return _imagem(fit, placeholder);
  }

  /// A imagem em si. [fundo] = cópia desfocada (sem indicador nem ícone).
  Widget _imagem(BoxFit fit, Widget placeholder, {bool fundo = false}) {
    final carregando = fundo
        ? const SizedBox.shrink()
        : const Center(child: CircularProgressIndicator(strokeWidth: 2));
    final erro = fundo ? const SizedBox.shrink() : placeholder;

    if (url!.startsWith('http')) {
      if (kIsWeb) {
        return Image.network(
          url!,
          fit: fit,
          width: double.infinity,
          height: height,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          loadingBuilder: (_, child, progresso) =>
              progresso == null ? child : carregando,
          errorBuilder: (_, e, __) {
            if (!fundo) _logarErro(url!, e);
            return erro;
          },
        );
      }
      return CachedNetworkImage(
        imageUrl: url!,
        fit: fit,
        width: double.infinity,
        height: height,
        placeholder: (_, __) => carregando,
        errorWidget: (_, __, e) {
          if (!fundo) _logarErro(url!, e);
          return erro;
        },
      );
    }

    return Image.asset(
      url!,
      fit: fit,
      width: double.infinity,
      height: height,
      errorBuilder: (_, e, __) {
        if (!fundo) _logarErro(url!, e);
        return erro;
      },
    );
  }
}

/// Foto inteira (BoxFit.contain) sobre uma cópia desfocada e ampliada dela
/// mesma: preenche um espaço de altura fixa sem recortar a foto.
///
/// Na Web o fundo é neutro: quando o bucket não libera CORS, a foto vira um
/// elemento <img> e o desfoque não se aplica (a cópia apareceria nítida).
class ImagemSemCorte extends StatelessWidget {
  /// Monta a imagem com o [BoxFit] pedido; [fundo] indica a cópia desfocada.
  final Widget Function(BoxFit fit, {required bool fundo}) imagem;

  const ImagemSemCorte({super.key, required this.imagem});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return ColoredBox(
        color: AppColors.background,
        child: imagem(BoxFit.contain, fundo: false),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: imagem(BoxFit.cover, fundo: true),
          ),
        ),
        // Escurece um pouco o fundo para a foto principal se destacar.
        const ColoredBox(color: Color(0x33000000)),
        imagem(BoxFit.contain, fundo: false),
      ],
    );
  }
}

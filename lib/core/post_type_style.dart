import 'package:flutter/material.dart';
import '../models/post_model.dart';
import 'app_colors.dart';

/// Cores de exibição de cada tipo de post (Perdi / Achei / Avistei).
/// Centralizado aqui para não repetir o mesmo switch em cada tela.
extension PostTypeStyle on PostType {
  /// Cor principal (texto, borda, etiqueta).
  Color get color {
    switch (this) {
      case PostType.lost:
        return AppColors.tagLost;
      case PostType.found:
        return AppColors.tagFound;
      case PostType.sighted:
        return AppColors.tagSighted;
    }
  }

  /// Cor de fundo clara usada atrás da etiqueta.
  Color get surface {
    switch (this) {
      case PostType.lost:
        return AppColors.tagLostSurface;
      case PostType.found:
        return AppColors.tagFoundSurface;
      case PostType.sighted:
        return AppColors.tagSightedSurface;
    }
  }
}

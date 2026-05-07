import 'package:flutter/material.dart';

/// Paleta de cores oficial do PetPerdido.
/// Baseada no protótipo: vermelho primário + cinzas neutros.
class AppColors {
  AppColors._();

  // Primárias
  static const Color primary = Color(0xFFE53935);
  static const Color primaryDark = Color(0xFFB71C1C);
  static const Color primaryLight = Color(0xFFEF9A9A);

  // Neutras
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFE0E0E0);

  // Tags de tipo de post
  static const Color tagLost = Color(0xFFE53935);    // Perdi
  static const Color tagFound = Color(0xFF43A047);   // Achei
  static const Color tagSighted = Color(0xFFFB8C00); // Avistei

  // Extras
  static const Color shadow = Color(0x1A000000);
  static const Color inputFill = Color(0xFFFAFAFA);
}

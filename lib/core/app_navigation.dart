import 'package:flutter/material.dart';

/// Chaves globais do MaterialApp. Permitem abrir telas e mostrar avisos
/// a partir de serviços (ex.: ao tocar numa notificação push).
class AppNavigation {
  AppNavigation._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();
}

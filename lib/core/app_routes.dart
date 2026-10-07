import 'package:flutter/material.dart';
import '../screens/auth/register_screen.dart';
import '../screens/post/create_post_screen.dart';

/// Gerenciamento centralizado de rotas nomeadas.
/// Login e tela principal não têm rota: quem decide entre elas é o
/// _AuthGate do main.dart, conforme o usuário está logado ou não.
class AppRoutes {
  AppRoutes._();

  static const String register = '/register';
  static const String createPost = '/create-post';

  static Map<String, WidgetBuilder> get routes => {
        register: (_) => const RegisterScreen(),
        createPost: (_) => const CreatePostScreen(),
      };
}

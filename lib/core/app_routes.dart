import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/main_screen.dart';
import '../screens/post/create_post_screen.dart';

/// Gerenciamento centralizado de rotas nomeadas.
class AppRoutes {
  AppRoutes._();

  static const String login = '/';
  static const String register = '/register';
  static const String main = '/main';
  static const String createPost = '/create-post';

  static Map<String, WidgetBuilder> get routes => {
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
        main: (_) => const MainScreen(),
        createPost: (_) => const CreatePostScreen(),
      };
}

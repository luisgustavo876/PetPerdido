import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_constants.dart';
import '../core/app_navigation.dart';
import '../screens/feed/detail_screen.dart';
import 'auth_service.dart';
import 'location_service.dart';
import 'post_service.dart';
import 'user_service.dart';

/// Alertas por proximidade (lado do app).
///
/// - Antes de pedir a localização, mostra um aviso de LGPD.
/// - Ao abrir o app e ao voltar do segundo plano (nunca em rastreamento
///   contínuo), grava a localização aproximada e o token do aparelho em
///   users/{uid}. A Cloud Function usa esses dados para avisar quem está perto.
/// - Trata o toque na notificação (abre o post) e a notificação com o app
///   aberto (banner dentro do app).
///
/// Push só no Android/iOS: na Web este serviço não faz nada.
class AlertaService {
  static bool _ouvintesRegistrados = false;
  static DateTime? _ultimaAtualizacao;

  /// Chamado uma vez quando a tela principal abre (usuário logado).
  static Future<void> iniciar() async {
    if (kIsWeb || AuthService.currentUser == null) return;
    _registrarOuvintes();
    try {
      final prefs = await UserService.preferenciasAlerta();
      var ativo = prefs.ativo;
      if (ativo == null) {
        ativo = await _pedirConsentimento();
        await UserService.definirAlertas(
            ativo: ativo, raioKm: AppConstants.alertRadiusPadraoKm);
      }
      if (ativo) await atualizar(pedirPermissao: prefs.ativo == null);
    } catch (e) {
      debugPrint('AlertaService: falha ao iniciar: $e');
    }
  }

  /// Ao voltar do segundo plano: atualiza se os alertas estão ligados e já
  /// passou [AppConstants.alertaIntervaloAtualizacao] desde a última vez.
  static Future<void> aoVoltarDoSegundoPlano() async {
    if (kIsWeb || AuthService.currentUser == null) return;
    final ultima = _ultimaAtualizacao;
    if (ultima != null &&
        DateTime.now().difference(ultima) <
            AppConstants.alertaIntervaloAtualizacao) {
      return;
    }
    try {
      final prefs = await UserService.preferenciasAlerta();
      if (prefs.ativo == true) await atualizar();
    } catch (e) {
      debugPrint('AlertaService: falha ao atualizar: $e');
    }
  }

  /// Grava token e localização aproximada. Com [pedirPermissao], pede as
  /// permissões de notificação e localização (só logo depois do aviso LGPD
  /// ou quando o usuário liga os alertas nas Configurações).
  static Future<void> atualizar({bool pedirPermissao = false}) async {
    if (kIsWeb) return;
    _ultimaAtualizacao = DateTime.now();

    final messaging = FirebaseMessaging.instance;
    if (pedirPermissao) await messaging.requestPermission();
    final token = await messaging.getToken();
    if (token != null) await UserService.salvarToken(token);

    ({double lat, double lng})? pos;
    if (pedirPermissao) {
      try {
        pos = await LocationService.posicaoAtual();
      } on LocationException catch (e) {
        _mostrarAviso(e.message);
      }
    } else {
      pos = await LocationService.posicaoSemPedir();
    }
    if (pos != null) {
      await UserService.salvarLocalizacao(
        LocationService.arredondar(pos.lat),
        LocationService.arredondar(pos.lng),
      );
    }
  }

  /// Ao sair da conta: este aparelho para de receber os alertas dela.
  static Future<void> sair() async {
    try {
      if (!kIsWeb) await UserService.salvarToken(null);
    } catch (_) {
      // Sem internet: segue com o logout mesmo assim.
    }
    _ultimaAtualizacao = null;
    await AuthService.signOut();
  }

  // ---------------------------------------------------------------------------
  // Mensagens recebidas
  // ---------------------------------------------------------------------------

  static void _registrarOuvintes() {
    if (_ouvintesRegistrados) return;
    _ouvintesRegistrados = true;
    final messaging = FirebaseMessaging.instance;

    messaging.onTokenRefresh.listen((token) {
      if (AuthService.currentUser != null) UserService.salvarToken(token);
    });

    // Toque na notificação com o app em segundo plano.
    FirebaseMessaging.onMessageOpenedApp.listen(_abrirDaMensagem);

    // Toque na notificação com o app fechado.
    messaging.getInitialMessage().then((msg) {
      if (msg != null) _abrirDaMensagem(msg);
    });

    // App aberto: o sistema não mostra a notificação; vira um banner.
    FirebaseMessaging.onMessage.listen(_mostrarBanner);
  }

  static void _abrirDaMensagem(RemoteMessage msg) {
    final postId = msg.data['postId'];
    if (postId is String && postId.isNotEmpty) abrirPost(postId);
  }

  /// Abre o Detalhe do post (ex.: a partir de um alerta).
  static Future<void> abrirPost(String postId) async {
    final post = await PostService.buscarPost(postId);
    final navigator = AppNavigation.navigatorKey.currentState;
    if (navigator == null) return;
    if (post == null) {
      _mostrarAviso('Este post não está mais disponível.');
      return;
    }
    navigator.push(MaterialPageRoute(builder: (_) => DetailScreen(post: post)));
  }

  static void _mostrarBanner(RemoteMessage msg) {
    final messenger = AppNavigation.messengerKey.currentState;
    if (messenger == null) return;
    final titulo = msg.notification?.title ?? 'Alerta do PetPerdido';
    final corpo = msg.notification?.body ?? '';
    final postId = msg.data['postId'] as String?;

    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(MaterialBanner(
      backgroundColor: AppColors.primarySurface,
      leading: const Icon(Icons.notifications_active, color: AppColors.primary),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (corpo.isNotEmpty) Text(corpo, style: const TextStyle(fontSize: 13)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: messenger.hideCurrentMaterialBanner,
          child: const Text('Fechar'),
        ),
        if (postId != null)
          TextButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              abrirPost(postId);
            },
            child: const Text('Ver'),
          ),
      ],
    ));
    // O banner some sozinho depois de alguns segundos.
    Timer(const Duration(seconds: 8), () {
      AppNavigation.messengerKey.currentState?.hideCurrentMaterialBanner();
    });
  }

  static void _mostrarAviso(String texto) {
    AppNavigation.messengerKey.currentState
        ?.showSnackBar(SnackBar(content: Text(texto)));
  }

  // ---------------------------------------------------------------------------
  // Aviso de LGPD
  // ---------------------------------------------------------------------------

  /// Explica, em linguagem simples, o que é guardado e para quê.
  /// Retorna true se a pessoa aceitar ativar os alertas.
  static Future<bool> _pedirConsentimento() async {
    final context = AppNavigation.navigatorKey.currentContext;
    if (context == null) return false;
    final aceitou = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.notifications_active,
            color: AppColors.primary, size: 40),
        title: const Text('Alertas de pets perto de você'),
        content: const SingleChildScrollView(
          child: Text(
            'Quando um pet sumir, for encontrado ou for visto perto de você, '
            'o PetPerdido pode te avisar.\n\n'
            'Para isso guardamos:\n'
            '• sua localização aproximada (cerca de 100 m), atualizada só '
            'quando você abre o app — não acompanhamos você em segundo plano;\n'
            '• um código do seu aparelho, para enviar a notificação.\n\n'
            'Esses dados não aparecem para outros usuários e servem só para os '
            'alertas. Você pode desligar quando quiser em Configurações.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Agora não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Ativar alertas'),
          ),
        ],
      ),
    );
    return aceitou ?? false;
  }
}

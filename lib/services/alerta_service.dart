import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_constants.dart';
import '../core/app_navigation.dart';
import '../screens/feed/detail_screen.dart';
import '../widgets/pet_image.dart';
import 'auth_service.dart';
import 'location_service.dart';
import 'post_service.dart';
import 'user_service.dart';

/// Alertas por proximidade (lado do app), no Android e no navegador.
///
/// - Antes de pedir a localização, mostra um aviso de LGPD.
/// - Ao abrir o app e ao voltar do segundo plano (nunca em rastreamento
///   contínuo), grava a localização aproximada e o token do aparelho (ou do
///   navegador) em users/{uid}. A Cloud Function usa esses dados para avisar
///   quem está perto.
/// - Trata o toque na notificação (abre o post) e a notificação com o app
///   aberto (banner dentro do app, com a foto).
///
/// Na Web o push usa o service worker `web/firebase-messaging-sw.js`
/// (Chrome, Edge, Firefox; no iPhone só com o site na tela de início).
class AlertaService {
  static bool _ouvintesRegistrados = false;
  static bool _urlTratada = false;
  static DateTime? _ultimaAtualizacao;

  /// Chamado uma vez quando a tela principal abre (usuário logado).
  static Future<void> iniciar() async {
    if (AuthService.currentUser == null) return;
    _registrarOuvintes();
    try {
      final prefs = await UserService.preferenciasAlerta();
      if (prefs.ativo == null) {
        final aceitou = await _pedirConsentimento();
        if (aceitou) {
          // Começa já (o navegador só mostra o pedido de notificação se ele
          // vier logo depois do toque em "Ativar alertas").
          final permissoes = atualizar(pedirPermissao: true);
          await UserService.definirAlertas(
              ativo: true, raioKm: AppConstants.alertRadiusPadraoKm);
          await permissoes;
        } else {
          await UserService.definirAlertas(
              ativo: false, raioKm: AppConstants.alertRadiusPadraoKm);
        }
      } else if (prefs.ativo == true) {
        await atualizar();
      }
    } catch (e) {
      debugPrint('AlertaService: falha ao iniciar: $e');
    }
  }

  /// Na Web, o toque na notificação abre o site com `?post=<id>`: abre o post.
  static void abrirPostDaUrl() {
    if (!kIsWeb || _urlTratada) return;
    _urlTratada = true;
    final postId = Uri.base.queryParameters['post'];
    if (postId != null && postId.isNotEmpty) abrirPost(postId);
  }

  /// Ao voltar do segundo plano: atualiza se os alertas estão ligados e já
  /// passou [AppConstants.alertaIntervaloAtualizacao] desde a última vez.
  static Future<void> aoVoltarDoSegundoPlano() async {
    if (AuthService.currentUser == null) return;
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
    _ultimaAtualizacao = DateTime.now();

    final messaging = FirebaseMessaging.instance;
    if (pedirPermissao) {
      // Primeira chamada (sem await antes): conta como resposta ao toque.
      final permissao = await messaging.requestPermission();
      if (permissao.authorizationStatus == AuthorizationStatus.denied) {
        _mostrarAviso(kIsWeb
            ? 'Notificações bloqueadas no navegador. Libere no cadeado ao lado '
                'do endereço do site para receber os alertas.'
            : 'Notificações desativadas. Libere nas configurações do aparelho '
                'para receber os alertas.');
      }
    }
    await _salvarToken(messaging, avisar: pedirPermissao);

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

  /// Token do push deste aparelho/navegador. Nunca lança erro: sem token
  /// (navegador sem suporte, notificação bloqueada) os alertas continuam no
  /// sino do app.
  static Future<void> _salvarToken(FirebaseMessaging messaging,
      {required bool avisar}) async {
    try {
      if (kIsWeb && !await messaging.isSupported()) {
        if (avisar) {
          _mostrarAviso('Este navegador não recebe notificações. No iPhone, '
              'adicione o site à tela de início e abra por lá.');
        }
        return;
      }
      final token = await messaging.getToken();
      if (token != null) await UserService.salvarToken(token);
    } catch (e) {
      debugPrint('AlertaService: sem token de push: $e');
    }
  }

  /// Ao sair da conta: este aparelho para de receber os alertas dela.
  static Future<void> sair() async {
    try {
      await UserService.salvarToken(null);
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
    final imagem = msg.data['imagem'] as String?;

    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(MaterialBanner(
      backgroundColor: AppColors.primarySurface,
      leading: imagem == null
          ? const Icon(Icons.notifications_active, color: AppColors.primary)
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: PetImage(url: imagem, iconSize: 24),
              ),
            ),
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
            '• um código deste aparelho (ou navegador), para enviar a '
            'notificação.\n\n'
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

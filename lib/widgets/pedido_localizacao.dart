import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/app_colors.dart';
import '../core/app_navigation.dart';
import '../services/location_service.dart';

/// Pede a localização dentro do app, explicando o motivo ANTES do aviso do
/// sistema (Android) ou do navegador. Chamado sempre que o app abre e a
/// permissão ainda não está liberada; a pessoa pode responder "Agora não".
class PedidoLocalizacao {
  PedidoLocalizacao._();

  static Future<void> verificar() async {
    final estado = await LocationService.estadoPermissao();
    switch (estado) {
      case EstadoLocalizacao.liberada:
        // Já liberada: só atualiza a posição (mapa e feed escutam).
        await LocationService.posicaoSemPedir();
      case EstadoLocalizacao.indisponivel:
        return;
      case EstadoLocalizacao.naoLiberada:
        if (await _perguntar() != true) return;
        try {
          await LocationService.posicaoAtual(); // abre o aviso do sistema
        } on LocationException catch (e) {
          _aviso(e.message);
        }
      case EstadoLocalizacao.bloqueada:
        await _explicarBloqueio();
      case EstadoLocalizacao.gpsDesligado:
        await _explicarGpsDesligado();
    }
  }

  static BuildContext? get _contexto {
    final c = AppNavigation.navigatorKey.currentContext;
    return c != null && c.mounted ? c : null;
  }

  static void _aviso(String texto) => AppNavigation.messengerKey.currentState
      ?.showSnackBar(SnackBar(content: Text(texto)));

  /// "Permitir sua localização?" Retorna true se tocar em Permitir.
  static Future<bool?> _perguntar() {
    final context = _contexto;
    if (context == null) return Future.value(false);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.location_on, color: AppColors.primary, size: 40),
        title: const Text('Permitir sua localização'),
        content: const SingleChildScrollView(
          child: Text(
            'O PetPerdido usa a sua localização para:\n'
            '• mostrar no mapa os pets perdidos perto de você;\n'
            '• marcar com um toque onde você viu um pet;\n'
            '• avisar quando um pet sumir por perto (se ativar os alertas).\n\n'
            'Ela só é usada com o app aberto, e a sua posição exata nunca '
            'aparece para outras pessoas.',
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
            child: const Text('Permitir localização'),
          ),
        ],
      ),
    );
  }

  /// Permissão bloqueada: o app não pode pedir de novo, só explicar o caminho.
  static Future<void> _explicarBloqueio() async {
    final context = _contexto;
    if (context == null) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.location_off, color: AppColors.primary, size: 40),
        title: const Text('Localização bloqueada'),
        content: Text(kIsWeb
            ? 'O navegador está bloqueando a localização deste site. Toque no '
                'cadeado ao lado do endereço, em Permissões (ou Configurações do '
                'site) → Localização → Permitir, e recarregue a página.'
            : 'A permissão de localização foi negada. Em Configurações do app '
                '→ Permissões → Localização, escolha "Permitir durante o uso".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Agora não'),
          ),
          if (!kIsWeb)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Geolocator.openAppSettings();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Abrir configurações'),
            ),
        ],
      ),
    );
  }

  /// GPS desligado no aparelho (Android).
  static Future<void> _explicarGpsDesligado() async {
    final context = _contexto;
    if (context == null) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.gps_off, color: AppColors.primary, size: 40),
        title: const Text('Localização do aparelho desligada'),
        content: const Text(
            'Ligue a localização (GPS) para ver os pets perto de você e marcar '
            'onde viu um pet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Agora não'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openLocationSettings();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Ligar localização'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/notificacao_model.dart';
import '../services/alerta_service.dart';
import '../services/user_service.dart';
import 'alerts/alertas_screen.dart';
import 'chat/chats_screen.dart';
import 'feed/feed_screen.dart';
import 'map/map_screen.dart';
import 'profile/points_screen.dart';
import 'profile/settings_screen.dart';

/// Tela principal (usuário logado): Mapa, Feed, Pontos e Chats, com o sino
/// de alertas e o atalho para Configurações.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  /// Stream único da tela: notificações (para o contador do sino).
  late final Stream<List<NotificacaoModel>> _notificacoesStream;

  final List<Widget> _screens = const [
    MapScreen(),
    FeedScreen(),
    PointsScreen(),
    ChatsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _notificacoesStream = UserService.notificacoesStream();
    WidgetsBinding.instance.addObserver(this);
    // Depois do primeiro quadro: o aviso de LGPD precisa da tela montada.
    WidgetsBinding.instance.addPostFrameCallback((_) => AlertaService.iniciar());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Voltou do segundo plano: atualiza a localização dos alertas (se ligados).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AlertaService.aoVoltarDoSegundoPlano();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
        child: Image.asset('assets/images/paw-logo.png', fit: BoxFit.contain),
      ),
      leadingWidth: 44,
      title: const Text(
        'PetPerdido',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: AppColors.primary,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        StreamBuilder<List<NotificacaoModel>>(
          stream: _notificacoesStream,
          builder: (context, snapshot) {
            final naoLidas =
                (snapshot.data ?? const []).where((n) => !n.lida).length;
            return IconButton(
              tooltip: 'Alertas',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlertasScreen()),
              ),
              icon: Badge(
                isLabelVisible: naoLidas > 0,
                label: Text(naoLidas > 9 ? '9+' : '$naoLidas'),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.notifications_none,
                    color: AppColors.textSecondary),
              ),
            );
          },
        ),
        IconButton(
          tooltip: 'Configurações e perfil',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          icon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.divider, height: 1),
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.feed_outlined),
            selectedIcon: Icon(Icons.feed),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.stars_outlined),
            selectedIcon: Icon(Icons.stars),
            label: 'Pontos',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../models/notificacao_model.dart';
import '../../services/alerta_service.dart';
import '../../services/user_service.dart';

/// Lista de alertas recebidos (users/{uid}/notifications).
class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  /// Stream único da tela, criado no initState.
  late Stream<List<NotificacaoModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = UserService.notificacoesStream();
  }

  Future<void> _abrir(NotificacaoModel n) async {
    if (!n.lida) UserService.marcarLida(n.id);
    final postId = n.postId;
    if (postId != null) await AlertaService.abrirPost(postId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificacaoModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        final lista = snapshot.data ?? const <NotificacaoModel>[];
        final naoLidas = lista.where((n) => !n.lida).map((n) => n.id).toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Alertas'),
            actions: [
              if (naoLidas.isNotEmpty)
                TextButton(
                  onPressed: () => UserService.marcarTodasLidas(naoLidas),
                  child: const Text('Marcar todas como lidas'),
                ),
            ],
          ),
          body: _corpo(snapshot, lista),
        );
      },
    );
  }

  Widget _corpo(
      AsyncSnapshot<List<NotificacaoModel>> snapshot, List<NotificacaoModel> lista) {
    if (snapshot.hasError) {
      return _estado(
        Icons.cloud_off,
        'Não foi possível carregar os alertas.',
        acao: ElevatedButton(
          onPressed: () =>
              setState(() => _stream = UserService.notificacoesStream()),
          child: const Text('Tentar de novo'),
        ),
      );
    }
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (lista.isEmpty) {
      return _estado(
        Icons.notifications_none,
        'Nenhum alerta por enquanto.\nQuando sair um post perto de você, '
        'ele aparece aqui.',
      );
    }
    return ListView.separated(
      itemCount: lista.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final n = lista[i];
        return ListTile(
          onTap: () => _abrir(n),
          tileColor: n.lida ? null : AppColors.primarySurface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: n.lida ? AppColors.background : AppColors.primary,
            child: Icon(Icons.pets,
                color: n.lida ? AppColors.textTertiary : Colors.white, size: 20),
          ),
          title: Text(
            n.titulo,
            style: TextStyle(
                fontWeight: n.lida ? FontWeight.w500 : FontWeight.w800),
          ),
          subtitle: Text('${n.corpo}\n'
              '${Formatters.tempoRelativo(n.createdAt, DateTime.now())}'),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        );
      },
    );
  }

  Widget _estado(IconData icone, String texto, {Widget? acao}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(texto,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            if (acao != null) ...[const SizedBox(height: 16), acao],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../models/chat_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

/// Lista de conversas em tempo real (mais recentes primeiro), com a última
/// mensagem e o número de não lidas.
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  /// Stream único da tela, criado no initState.
  late Stream<List<ChatModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = ChatService.minhasConversas();
  }

  @override
  Widget build(BuildContext context) {
    final eu = AuthService.currentUser?.uid ?? '';
    return StreamBuilder<List<ChatModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _estado(
            Icons.cloud_off,
            'Não foi possível carregar as conversas.',
            acao: ElevatedButton(
              onPressed: () =>
                  setState(() => _stream = ChatService.minhasConversas()),
              child: const Text('Tentar de novo'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final conversas = snapshot.data!;
        if (conversas.isEmpty) {
          return _estado(
            Icons.chat_bubble_outline,
            'Nenhuma conversa ainda.\nAbra um post e toque em "Entrar em contato".',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: conversas.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, i) => _item(conversas[i], eu),
        );
      },
    );
  }

  Widget _item(ChatModel c, String eu) {
    final naoLidas = c.naoLidas(eu);
    final nome = c.nomeDoOutro(eu);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(chat: c)),
      ),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primarySurface,
        child: Text(nome.isNotEmpty ? nome[0].toUpperCase() : '?',
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.primary)),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: naoLidas > 0 ? FontWeight.w800 : FontWeight.w600)),
          ),
          if (c.lastMessageAt != null)
            Text(
              Formatters.tempoRelativo(c.lastMessageAt!, DateTime.now()),
              style: TextStyle(
                fontSize: 11,
                color: naoLidas > 0 ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.postTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.primary)),
          Row(
            children: [
              Expanded(
                child: Text(
                  c.lastMessage.isEmpty ? 'Conversa iniciada' : c.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: naoLidas > 0 ? AppColors.onSurface : AppColors.textSecondary,
                    fontWeight: naoLidas > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (naoLidas > 0)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('$naoLidas',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ],
      ),
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

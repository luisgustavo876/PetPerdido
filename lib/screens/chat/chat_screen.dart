import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/dados_globais.dart';
import '../../models/post_model.dart';

class ChatScreen extends StatefulWidget {
  final PostModel post;

  const ChatScreen({super.key, required this.post});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scrollar para o final após renderizar
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage({String? photoUrl}) {
    final text = _msgController.text.trim();
    if (text.isEmpty && photoUrl == null) return;

    setState(() {
      DadosGlobais.adicionarMensagem(
        widget.post.id,
        'myUser',
        'Você',
        text,
      );
    });

    _msgController.clear();
    // Forçar rolagem para baixo
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Simulação rápida de resposta do tutor após 1.5 segundos (se for o primeiro contato)
    if (widget.post.id == '3' && (DadosGlobais.chats[widget.post.id]?.length ?? 0) == 1) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            DadosGlobais.adicionarMensagem(
              widget.post.id,
              widget.post.userId,
              widget.post.userName,
              'Muito obrigado pelo contato! Onde exatamente você encontrou ele?',
            );
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 48,
        titleSpacing: 0,
        title: Row(
          children: [
            // Foto circular pequena
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              backgroundImage: widget.post.photoUrl != null
                  ? AssetImage(widget.post.photoUrl!)
                  : null,
              child: widget.post.photoUrl == null
                  ? const Icon(Icons.pets, size: 16)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.userName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ajudando com ${widget.post.petName.isNotEmpty && widget.post.petName != 'Sem nome' ? widget.post.petName : 'Pet'}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Última localização: ${widget.post.lastSeenAddress}'),
                ),
              );
            },
            tooltip: 'Ver localização do pet',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  final messages = DadosGlobais.chats[widget.post.id] ?? [];

                  if (messages.isEmpty) {
                    return _buildWelcomeMessage();
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg['senderId'] == 'myUser';
                      final showAvatar = !isMe &&
                          (index == messages.length - 1 ||
                              messages[index + 1]['senderId'] != msg['senderId']);

                      return _buildMessageBubble(
                        text: msg['message'],
                        isMe: isMe,
                        time: msg['createdAt'],
                        photo: msg['photoUrl'],
                        showAvatar: showAvatar,
                      );
                    },
                  );
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Inicie uma conversa com ${widget.post.userName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Troque informações seguras sobre o paradeiro de ${widget.post.petName.isNotEmpty && widget.post.petName != 'Sem nome' ? widget.post.petName : 'este pet'}.',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final text = msg['message'] as String;
    final time = msg['createdAt'] as DateTime;
    final photo = msg['photoUrl'] as String?;
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: widget.post.ownerAvatar != null ? NetworkImage(widget.post.ownerAvatar!) : null,
              child: widget.post.ownerAvatar == null
                  ? Text(widget.post.userName[0].toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (photo != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(photo, height: 150, width: 200, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (text.isNotEmpty)
                    Text(
                      text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        timeString,
                        style: TextStyle(
                          fontSize: 9,
                          color: isMe ? Colors.white70 : Colors.grey,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all, size: 10, color: Colors.white70),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Anexar foto
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined, color: Colors.grey),
              onPressed: () => _simulateSendPhoto(context),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TextField(
                  controller: _msgController,
                  decoration: const InputDecoration(
                    hintText: 'Escreva uma mensagem...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 20,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 16),
                onPressed: () => _sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateSendPhoto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enviar Foto de Avistamento',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.add_photo_alternate, color: AppColors.primary),
                title: const Text('Simular Envio de Foto de Pet'),
                subtitle: const Text('Anexa a imagem do cão de avistamento mockado'),
                onTap: () {
                  Navigator.pop(context);
                  _sendMessage(photoUrl: 'assets/images/dog_sighted.png');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Foto anexada com sucesso!')),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

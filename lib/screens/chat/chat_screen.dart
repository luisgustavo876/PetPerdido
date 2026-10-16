import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/filtro_palavroes.dart';
import '../../core/formatters.dart';
import '../../models/chat_model.dart';
import '../../services/alerta_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/pet_image.dart';
import '../../widgets/seletor_imagem.dart';

/// Conversa em tempo real: texto e foto, filtro de palavrões e mensagens
/// que somem depois de 15 dias. Mostra só o NOME da outra pessoa.
class ChatScreen extends StatefulWidget {
  final ChatModel chat;

  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textoController = TextEditingController();
  final _rolagem = ScrollController();

  /// Stream único da tela, criado no initState.
  late Stream<List<MensagemModel>> _stream;
  String? _ultimaMarcada; // última mensagem recebida já marcada como lida
  bool _enviando = false;

  String get _eu => AuthService.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _stream = ChatService.mensagens(widget.chat.id);
    ChatService.marcarComoLida(widget.chat.id);
  }

  @override
  void dispose() {
    _textoController.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  /// Chegou mensagem da outra pessoa com a tela aberta: marca como lida
  /// (uma vez por mensagem nova) e rola para o fim.
  void _aoReceber(List<MensagemModel> msgs) {
    if (msgs.isEmpty) return;
    final ultima = msgs.last;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rolagem.hasClients) {
        _rolagem.animateTo(_rolagem.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
    if (ultima.senderId != _eu && ultima.id != _ultimaMarcada) {
      _ultimaMarcada = ultima.id;
      ChatService.marcarComoLida(widget.chat.id);
    }
  }

  Future<void> _enviarTexto() async {
    final texto = _textoController.text.trim();
    if (texto.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    try {
      await ChatService.enviarTexto(widget.chat, texto);
      _textoController.clear();
    } catch (_) {
      _aviso('Não foi possível enviar. Confira a internet e tente de novo.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _enviarFoto() async {
    if (_enviando) return;
    try {
      final foto = await SeletorImagem.escolher(context);
      if (foto == null) return;
      setState(() => _enviando = true);
      await ChatService.enviarFoto(widget.chat, foto);
    } catch (_) {
      _aviso('Não foi possível enviar a foto (imagem de até 5 MB).');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final nome = widget.chat.nomeDoOutro(_eu);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(widget.chat.postTitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ver o post',
            icon: const Icon(Icons.pets_outlined),
            onPressed: () => AlertaService.abrirPost(widget.chat.postId),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.tagSightedSurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              'Por segurança, combine a entrega em local público e não envie '
              'endereço, CPF ou documentos. As mensagens somem depois de 15 dias.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MensagemModel>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: TextButton(
                      onPressed: () => setState(() =>
                          _stream = ChatService.mensagens(widget.chat.id)),
                      child: const Text('Não foi possível carregar. Tentar de novo'),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final msgs = snapshot.data!;
                _aoReceber(msgs);
                if (msgs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Comece a conversa com $nome.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _rolagem,
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) => _balao(msgs[i]),
                );
              },
            ),
          ),
          _entrada(),
        ],
      ),
    );
  }

  Widget _balao(MensagemModel m) {
    final minha = m.senderId == _eu;
    final hora =
        '${m.createdAt.hour.toString().padLeft(2, '0')}:${m.createdAt.minute.toString().padLeft(2, '0')}';
    final texto = FiltroPalavroes.filtrar(m.texto); // também ao exibir
    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: minha ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(minha ? 16 : 4),
            bottomRight: Radius.circular(minha ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.fotoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 200,
                  height: 160,
                  child: PetImage(url: m.fotoUrl, iconSize: 32),
                ),
              ),
            if (texto.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Text(
                  texto,
                  style: TextStyle(
                      color: minha ? Colors.white : AppColors.onSurface, height: 1.4),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Text(
                '$hora · ${Formatters.tempoRelativo(m.createdAt, DateTime.now())}',
                style: TextStyle(
                    fontSize: 10,
                    color: minha ? Colors.white70 : AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entrada() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Enviar foto',
              onPressed: _enviando ? null : _enviarFoto,
              icon: const Icon(Icons.photo_camera_outlined),
            ),
            Expanded(
              child: TextField(
                controller: _textoController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _enviarTexto(),
                decoration: InputDecoration(
                  hintText: 'Escreva uma mensagem...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Enviar',
              onPressed: _enviando ? null : _enviarTexto,
              style: IconButton.styleFrom(backgroundColor: AppColors.primary),
              icon: _enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

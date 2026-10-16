import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../core/formatters.dart';
import '../../core/pet_options.dart';
import '../../core/post_type_style.dart';
import '../../models/post_model.dart';
import '../../models/sighting_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/pontos_service.dart';
import '../../services/post_service.dart';
import '../../services/user_service.dart';
import '../../widgets/pet_image.dart';
import '../chat/chat_screen.dart';
import 'widgets/eu_vi_sheet.dart';

/// Detalhe do post: dados do pet, avistamentos reais, favoritar,
/// compartilhar e, para o autor, marcar como resolvido e excluir.
class DetailScreen extends StatefulWidget {
  final PostModel post;

  const DetailScreen({super.key, required this.post});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  /// Cópia local, atualizada depois das ações (resolvido, novo avistamento).
  late PostModel _post = widget.post;

  /// Stream único da tela, criado no initState.
  late Stream<List<SightingModel>> _avistamentosStream;

  bool _favorito = false;
  bool _ocupado = false;

  String? get _meuUid => AuthService.currentUser?.uid;
  bool get _souAutor => _post.userId == _meuUid;

  @override
  void initState() {
    super.initState();
    _avistamentosStream = PostService.avistamentosStream(_post.id);
    _carregarFavorito();
  }

  Future<void> _carregarFavorito() async {
    try {
      final favs = await UserService.favoritos();
      if (mounted) setState(() => _favorito = favs.contains(_post.id));
    } catch (_) {
      // Se não conseguir ler, o coração só aparece vazio.
    }
  }

  void _mensagem(String texto) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _alternarFavorito() async {
    final novo = !_favorito;
    setState(() => _favorito = novo); // atualiza na hora
    try {
      await UserService.definirFavorito(_post.id, novo);
      _mensagem(novo ? 'Adicionado aos favoritos.' : 'Removido dos favoritos.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _favorito = !novo); // desfaz
      _mensagem('Não foi possível atualizar os favoritos.');
    }
  }

  Future<void> _compartilhar() async {
    await SharePlus.instance.share(ShareParams(
      text: Formatters.textoCompartilhar(_post),
      subject: 'PetPerdido: ${_post.type.label}',
    ));
  }

  Future<bool> _confirmar(String titulo, String texto, String botao) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Text(botao),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _marcarResolvido() async {
    final ok = await _confirmar(
      'Marcar como resolvido?',
      'O post sai do mapa e do feed (só aparece com o filtro "Incluir resolvidos").',
      'Marcar',
    );
    if (!ok) return;
    setState(() => _ocupado = true);
    try {
      await PostService.marcarResolvido(_post.id);
      if (!mounted) return;
      setState(() => _post = _post.copyWith(isResolved: true));
      _mensagem('Que bom! Post marcado como resolvido.');
    } catch (_) {
      if (mounted) _mensagem('Não foi possível atualizar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _excluir() async {
    final ok = await _confirmar(
      'Excluir este post?',
      'O post, os avistamentos e as fotos serão apagados. Não dá para desfazer.',
      'Excluir',
    );
    if (!ok || !mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _ocupado = true);
    try {
      await PostService.excluirPost(_post);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Post excluído.')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _ocupado = false);
      _mensagem('Não foi possível excluir. Tente novamente.');
    }
  }

  /// "Entrar em contato": abre (ou cria) a conversa com quem publicou.
  Future<void> _entrarEmContato() async {
    setState(() => _ocupado = true);
    try {
      final chat = await ChatService.abrirOuCriar(_post);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
      );
    } on ChatException catch (e) {
      _mensagem(e.mensagem);
    } catch (_) {
      _mensagem('Não foi possível abrir a conversa. Tente novamente.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _euVi() async {
    final registrou = await EuViSheet.abrir(context, _post.id);
    if (!registrou) return;
    await PontosService.ganharPorAvistamento(_post.id); // +15, uma vez por post
    if (!mounted) return;
    setState(() => _post = _post.copyWith(
          sightingsCount: _post.sightingsCount + 1,
          helpersCount: _post.helpersCount + 1,
        ));
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.tagFound, size: 48),
        title: const Text('Obrigado!'),
        content: const Text(
          'Seu avistamento foi registrado e já aparece para quem publicou.\n\n'
          '+${AppConstants.pontosEuVi} pontos!',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ótimo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SightingModel>>(
      stream: _avistamentosStream,
      builder: (context, snapshot) {
        final avistamentos = snapshot.data ?? const <SightingModel>[];
        final jaAvistei = avistamentos.any((s) => s.userId == _meuUid);
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _hero(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_post.isResolved) ...[
                        _avisoResolvido(),
                        const SizedBox(height: 16),
                      ],
                      _cabecalho(),
                      const SizedBox(height: 24),
                      _fichaTecnica(),
                      if (_post.traits.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _titulo('Características'),
                        _chips(_post.traits),
                      ],
                      const SizedBox(height: 24),
                      _titulo('Descrição'),
                      Text(
                        _post.description,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      _titulo('Publicado por'),
                      _autor(),
                      const SizedBox(height: 24),
                      _titulo('Avistamentos (${_post.sightingsCount})'),
                      _linhaDoTempo(snapshot, avistamentos),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _acoes(jaAvistei),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Partes da tela
  // ---------------------------------------------------------------------------

  Widget _titulo(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          texto,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      );

  Widget _hero() {
    return Stack(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          color: AppColors.background,
          child: PetImage(url: _post.photoUrl, iconSize: 80),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 104,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black45, Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: 16,
          child: _botaoHero(Icons.arrow_back, 'Voltar',
              () => Navigator.pop(context)),
        ),
        Positioned(
          top: 40,
          right: 16,
          child: Row(
            children: [
              _botaoHero(Icons.share_outlined, 'Compartilhar', _compartilhar),
              const SizedBox(width: 8),
              _botaoHero(
                _favorito ? Icons.favorite : Icons.favorite_border,
                _favorito ? 'Remover dos favoritos' : 'Favoritar',
                _alternarFavorito,
                cor: _favorito ? AppColors.primary : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _botaoHero(IconData icone, String dica, VoidCallback onTap,
      {Color? cor}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: dica,
        onPressed: onTap,
        icon: Icon(icone, size: 20, color: cor ?? AppColors.onSurface),
      ),
    );
  }

  Widget _avisoResolvido() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tagFoundSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified, color: AppColors.tagFound),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Caso resolvido. Obrigado a todos que ajudaram!',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.tagFound),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cabecalho() {
    final nome = _post.petName.isNotEmpty && _post.petName != 'Sem nome'
        ? _post.petName
        : 'Pet sem nome';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                nome,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _post.type.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _post.type.label,
                style: TextStyle(
                  color: _post.type.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _linhaInfo(Icons.location_on_outlined, _post.lastSeenAddress),
        const SizedBox(height: 4),
        _linhaInfo(Icons.event_outlined,
            '${formatarDataHora(_post.eventAt)} · ${Formatters.tempoRelativo(_post.eventAt, DateTime.now())}'),
      ],
    );
  }

  Widget _linhaInfo(IconData icone, String texto) {
    return Row(
      children: [
        Icon(icone, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(texto,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _fichaTecnica() {
    Widget item(String rotulo, String valor, IconData icone) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(icone, color: AppColors.primary, size: 18),
                const SizedBox(height: 8),
                Text(rotulo,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textTertiary)),
                const SizedBox(height: 4),
                Text(
                  valor,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            item('Espécie', _post.species, Icons.pets_outlined),
            const SizedBox(width: 8),
            item('Raça', _post.breed, Icons.category_outlined),
            const SizedBox(width: 8),
            item('Porte', _post.size, Icons.straighten),
            const SizedBox(width: 8),
            item('Sexo', _post.sex, Icons.wc_outlined),
          ],
        ),
        if (_post.colors.isNotEmpty) ...[
          const SizedBox(height: 16),
          _titulo('Cor'),
          _chips(_post.colors),
        ],
      ],
    );
  }

  Widget _chips(List<String> itens) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in itens)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(item,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
      ],
    );
  }

  Widget _autor() {
    final inicial =
        _post.userName.isNotEmpty ? _post.userName[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primarySurface,
            backgroundImage: PetImage.provider(_post.ownerAvatar),
            child: _post.ownerAvatar == null
                ? Text(inicial,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.primary))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_souAutor ? '${_post.userName} (você)' : _post.userName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Publicado ${Formatters.tempoRelativo(_post.createdAt, DateTime.now())}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaDoTempo(AsyncSnapshot<List<SightingModel>> snapshot,
      List<SightingModel> avistamentos) {
    if (snapshot.hasError) {
      return _caixa(
        'Não foi possível carregar os avistamentos.',
        acao: TextButton(
          onPressed: () => setState(() => _avistamentosStream =
              PostService.avistamentosStream(_post.id)),
          child: const Text('Tentar de novo'),
        ),
      );
    }
    if (!snapshot.hasData) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (avistamentos.isEmpty) {
      return _caixa('Nenhum avistamento registrado ainda.');
    }
    return Column(
      children: [
        for (var i = 0; i < avistamentos.length; i++)
          _itemLinhaDoTempo(avistamentos[i],
              ultimo: i == avistamentos.length - 1),
      ],
    );
  }

  Widget _itemLinhaDoTempo(SightingModel s, {required bool ultimo}) {
    final quem = s.userId == _meuUid ? 'Você' : s.userName;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!ultimo)
                  Expanded(
                    child: Container(width: 2, color: AppColors.divider),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: ultimo ? 0 : 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(s.address,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                      Text(
                        Formatters.tempoRelativo(s.createdAt, DateTime.now()),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Visto por $quem',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  if (s.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(s.notes, style: const TextStyle(fontSize: 13)),
                  ],
                  if (s.photoUrl != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: PetImage(url: s.photoUrl, iconSize: 32),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _caixa(String texto, {Widget? acao}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(texto,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          if (acao != null) acao,
        ],
      ),
    );
  }

  /// Barra de ações: autor (resolver/excluir) ou visitante ("Eu vi").
  Widget? _acoes(bool jaAvistei) {
    final List<Widget> botoes;
    if (_souAutor) {
      botoes = [
        OutlinedButton.icon(
          onPressed: _ocupado ? null : _excluir,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
            foregroundColor: AppColors.primary,
          ),
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Excluir'),
        ),
        if (!_post.isResolved) ...[
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _ocupado ? null : _marcarResolvido,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Marcar como resolvido'),
            ),
          ),
        ],
      ];
    } else {
      final contato = OutlinedButton.icon(
        onPressed: _ocupado ? null : _entrarEmContato,
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: const Text('Entrar em contato'),
      );
      botoes = _post.isResolved
          ? [Expanded(child: contato)]
          : [
              contato,
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: jaAvistei ? null : _euVi,
                  icon: Icon(jaAvistei ? Icons.check : Icons.visibility, size: 18),
                  label: Text(jaAvistei ? 'Já registrado' : 'Eu vi este pet'),
                ),
              ),
            ];
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(top: false, child: Row(children: botoes)),
    );
  }
}

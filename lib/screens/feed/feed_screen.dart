import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/geo.dart';
import '../../models/post_filter.dart';
import '../../models/post_model.dart';
import '../../services/location_service.dart';
import '../../services/post_service.dart';
import '../../widgets/filtros_sheet.dart';
import '../../widgets/pet_post_card.dart';
import 'detail_screen.dart';

/// Feed: lista de posts com busca, filtros e ordenação.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  /// Stream único da tela, criado no initState (nunca dentro do build).
  late Stream<List<PostModel>> _postsStream;

  /// O campo de busca fica FORA do StreamBuilder e tem controller próprio,
  /// então não perde o texto quando a lista atualiza.
  final _buscaController = TextEditingController();
  String _busca = '';

  PostFilter _filtro = const PostFilter();
  ({double lat, double lng})? _minhaPosicao;

  static const _atalhosTipo = [
    (null, 'Todos'),
    (PostType.lost, 'Perdidos'),
    (PostType.sighted, 'Avistados'),
    (PostType.found, 'Achados'),
  ];

  @override
  void initState() {
    super.initState();
    _postsStream = PostService.postsStream();
    _posicaoSemPedir();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _tentarDeNovo() =>
      setState(() => _postsStream = PostService.postsStream());

  /// Distâncias nos cards, se o usuário já tiver dado permissão de localização.
  Future<void> _posicaoSemPedir() async {
    final pos = await LocationService.posicaoSemPedir();
    if (pos != null && mounted) setState(() => _minhaPosicao = pos);
  }

  Future<void> _abrirFiltros() async {
    final novo = await FiltrosSheet.abrir(
      context,
      inicial: _filtro,
      mostrarPorte: true,
      mostrarCor: true,
      mostrarResolvidos: true,
      mostrarOrdem: true,
    );
    if (novo == null || !mounted) return;
    setState(() => _filtro = novo);
    if (novo.ordem == OrdemFeed.maisPerto && _minhaPosicao == null) {
      await _pedirPosicao();
    }
  }

  /// "Mais perto de mim" precisa da localização: pede permissão agora.
  Future<void> _pedirPosicao() async {
    try {
      final pos = await LocationService.posicaoAtual();
      if (mounted) setState(() => _minhaPosicao = pos);
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() => _filtro = _filtro.copyWith(ordem: OrdemFeed.recentes));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${e.message} Mostrando os mais recentes.')));
    }
  }

  double? _distancia(PostModel p) {
    final eu = _minhaPosicao;
    if (eu == null) return null;
    return Geo.distanciaKm(eu.lat, eu.lng, p.latitude, p.longitude);
  }

  List<PostModel> _aplicar(List<PostModel> posts) {
    final agora = DateTime.now();
    final lista = posts
        .where((p) => _filtro.aceita(p, agora: agora))
        .where((p) => PostFilter.buscaCorresponde(p, _busca))
        .toList();
    if (_filtro.ordem == OrdemFeed.maisPerto && _minhaPosicao != null) {
      lista.sort((a, b) => _distancia(a)!.compareTo(_distancia(b)!));
    }
    return lista;
  }

  Future<void> _abrirDetalhe(PostModel post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(post: post)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _cabecalho(),
          Expanded(
            child: StreamBuilder<List<PostModel>>(
              stream: _postsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) return _estadoErro();
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final todos = snapshot.data!;
                final posts = _aplicar(todos);
                if (posts.isEmpty) return _estadoVazio(semPosts: todos.isEmpty);
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 32),
                  itemCount: posts.length,
                  itemBuilder: (context, i) => PetPostCard(
                    post: posts[i],
                    distanciaKm: _distancia(posts[i]),
                    onTap: () => _abrirDetalhe(posts[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _cabecalho() {
    final filtros = _filtro.quantidadeAtivos;
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _buscaController,
                    onChanged: (texto) => setState(() => _busca = texto),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome, raça, cor, bairro...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _busca.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpar busca',
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() {
                                _buscaController.clear();
                                _busca = '';
                              }),
                            ),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Badge(
                  isLabelVisible: filtros > 0,
                  label: Text('$filtros'),
                  backgroundColor: AppColors.primary,
                  child: IconButton.outlined(
                    tooltip: 'Filtros e ordem',
                    onPressed: _abrirFiltros,
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              children: [
                for (final (tipo, rotulo) in _atalhosTipo) ...[
                  _atalhoTipo(tipo, rotulo),
                  const SizedBox(width: 8),
                ],
                if (_filtro.ordem == OrdemFeed.maisPerto)
                  const Chip(
                    avatar: Icon(Icons.near_me, size: 16),
                    label: Text('Mais perto'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  /// Atalhos rápidos de tipo (o mesmo filtro do painel).
  Widget _atalhoTipo(PostType? tipo, String rotulo) {
    final selecionado = tipo == null
        ? _filtro.tipos.isEmpty
        : _filtro.tipos.length == 1 && _filtro.tipos.contains(tipo);
    return ChoiceChip(
      label: Text(rotulo),
      selected: selecionado,
      onSelected: (_) => setState(() =>
          _filtro = _filtro.copyWith(tipos: tipo == null ? {} : {tipo})),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selecionado ? Colors.white : AppColors.textSecondary,
      ),
    );
  }

  Widget _estadoVazio({required bool semPosts}) {
    final temFiltro = _filtro.quantidadeAtivos > 0 || _busca.isNotEmpty;
    return _Estado(
      icone: semPosts ? Icons.pets : Icons.search_off,
      titulo: semPosts ? 'Ainda não há posts' : 'Nenhum pet encontrado',
      texto: semPosts
          ? 'Quando alguém publicar, o post aparece aqui.'
          : 'Tente outros termos ou altere os filtros.',
      acao: temFiltro
          ? OutlinedButton(
              onPressed: () => setState(() {
                _filtro = PostFilter(ordem: _filtro.ordem);
                _buscaController.clear();
                _busca = '';
              }),
              child: const Text('Limpar busca e filtros'),
            )
          : null,
    );
  }

  Widget _estadoErro() {
    return _Estado(
      icone: Icons.cloud_off,
      titulo: 'Não foi possível carregar os posts',
      texto: 'Confira sua conexão com a internet.',
      acao: ElevatedButton(
        onPressed: _tentarDeNovo,
        child: const Text('Tentar de novo'),
      ),
    );
  }
}

/// Estado vazio ou de erro, centralizado.
class _Estado extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String texto;
  final Widget? acao;

  const _Estado({
    required this.icone,
    required this.titulo,
    required this.texto,
    this.acao,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Icon(icone, size: 36, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            Text(titulo,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(texto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            if (acao != null) ...[
              const SizedBox(height: 16),
              SizedBox(width: 240, child: acao),
            ],
          ],
        ),
      ),
    );
  }
}

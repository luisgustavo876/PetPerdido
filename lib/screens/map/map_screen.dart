import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../core/app_routes.dart';
import '../../core/geo.dart';
import '../../core/post_type_style.dart';
import '../../models/post_filter.dart';
import '../../models/post_model.dart';
import '../../services/location_service.dart';
import '../../services/post_service.dart';
import '../../widgets/filtros_sheet.dart';
import '../../widgets/pet_image.dart';
import '../feed/detail_screen.dart';

/// Mapa com os posts: marcadores coloridos por tipo, filtros reais,
/// camada satélite e "Minha localização".
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _centroPadrao = CameraPosition(
    target: LatLng(AppConstants.defaultLat, AppConstants.defaultLng),
    zoom: 13.8,
  );

  GoogleMapController? _mapController;

  /// Stream único da tela, criado no initState (nunca dentro do build).
  late Stream<List<PostModel>> _postsStream;

  PostFilter _filtro = const PostFilter();
  MapType _camada = MapType.normal;
  LatLng? _minhaPosicao;
  bool _localizando = false;

  @override
  void initState() {
    super.initState();
    _postsStream = PostService.postsStream();
    _centralizarSemPedir();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _tentarDeNovo() =>
      setState(() => _postsStream = PostService.postsStream());

  /// Câmera inicial: posição do usuário, se ele já deu permissão antes.
  Future<void> _centralizarSemPedir() async {
    final pos = await LocationService.posicaoSemPedir();
    if (pos == null || !mounted) return;
    setState(() => _minhaPosicao = LatLng(pos.lat, pos.lng));
    _moverCamera(CameraUpdate.newLatLngZoom(_minhaPosicao!, 14));
  }

  /// Botão "Minha localização": pede permissão se precisar e centraliza.
  Future<void> _irParaMinhaLocalizacao() async {
    setState(() => _localizando = true);
    try {
      final pos = await LocationService.posicaoAtual();
      if (!mounted) return;
      setState(() => _minhaPosicao = LatLng(pos.lat, pos.lng));
      _moverCamera(CameraUpdate.newLatLngZoom(_minhaPosicao!, 15));
    } on LocationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _localizando = false);
    }
  }

  Future<void> _abrirFiltros() async {
    final novo = await FiltrosSheet.abrir(
      context,
      inicial: _filtro,
      mostrarPeriodo: true,
      mostrarResolvidos: true,
    );
    if (novo != null && mounted) setState(() => _filtro = novo);
  }

  void _alternarCamada() => setState(() => _camada =
      _camada == MapType.normal ? MapType.hybrid : MapType.normal);

  /// Move a câmera sem deixar escapar erro do mapa (a chamada não é esperada).
  Future<void> _moverCamera(CameraUpdate destino) async {
    try {
      await _mapController?.animateCamera(destino);
    } catch (e) {
      debugPrint('MapScreen: não moveu a câmera: $e');
    }
  }

  /// Toque no aviso "Há N pets perdidos na região": mostra só os perdidos e
  /// enquadra o mapa neles (marcadores tocáveis para ver o resumo).
  void _mostrarPerdidos(List<PostModel> perdidos) {
    if (perdidos.isEmpty) return;
    setState(() => _filtro = _filtro.copyWith(tipos: {PostType.lost}));
    final l = Geo.limites(
        [for (final p in perdidos) (lat: p.latitude, lng: p.longitude)])!;
    _moverCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(l.sul, l.oeste),
        northeast: LatLng(l.norte, l.leste),
      ),
      72,
    ));
  }

  Set<Marker> _marcadores(List<PostModel> posts) {
    return {
      for (final post in posts)
        Marker(
          markerId: MarkerId(post.id),
          position: LatLng(post.latitude, post.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(_matiz(post.type)),
          alpha: post.isResolved ? 0.5 : 1,
          onTap: () => _abrirResumo(post),
        ),
      // Na Web o mapa não desenha o ponto azul nativo: usa um marcador azul.
      if (kIsWeb && _minhaPosicao != null)
        Marker(
          markerId: const MarkerId('minha-posicao'),
          position: _minhaPosicao!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Você está aqui'),
        ),
    };
  }

  double _matiz(PostType tipo) => switch (tipo) {
        PostType.lost => BitmapDescriptor.hueRed,
        PostType.found => BitmapDescriptor.hueGreen,
        PostType.sighted => BitmapDescriptor.hueOrange,
      };

  void _abrirResumo(PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResumoPost(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<PostModel>>(
        stream: _postsStream,
        builder: (context, snapshot) {
          final todos = snapshot.data ?? const <PostModel>[];
          final agora = DateTime.now();
          final visiveis =
              todos.where((p) => _filtro.aceita(p, agora: agora)).toList();
          final perdidos = visiveis
              .where((p) => p.type == PostType.lost && !p.isResolved)
              .toList();
          final carregando = !snapshot.hasData && !snapshot.hasError;

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: _minhaPosicao == null
                    ? _centroPadrao
                    : CameraPosition(target: _minhaPosicao!, zoom: 14),
                mapType: _camada,
                markers: _marcadores(visiveis),
                myLocationEnabled: !kIsWeb && _minhaPosicao != null,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (c) => _mapController = c,
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: snapshot.hasError
                    ? _avisoErro()
                    : _bannerAlerta(perdidos, carregando,
                        vazio: !carregando && visiveis.isEmpty),
              ),
              Positioned(right: 16, top: 104, child: _controles()),
              Positioned(left: 16, bottom: 88, child: _legenda()),
              Positioned(right: 16, bottom: 24, child: _botaoCriar(context)),
            ],
          );
        },
      ),
    );
  }

  /// Aviso do topo. Com pets perdidos, é tocável: leva até eles no mapa.
  Widget _bannerAlerta(List<PostModel> perdidos, bool carregando,
      {required bool vazio}) {
    final n = perdidos.length;
    final texto = carregando
        ? 'Carregando posts...'
        : vazio
            ? 'Nenhum post com esses filtros.'
            : 'Há $n pet${n != 1 ? 's' : ''} '
                'perdido${n != 1 ? 's' : ''} na região!';
    final tocavel = !carregando && n > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: tocavel ? () => _mostrarPerdidos(perdidos) : null,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFFFF5722)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              carregando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.notifications_active,
                      color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      texto,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (tocavel)
                      Text(
                        n == 1
                            ? 'Toque para ver no mapa'
                            : 'Toque para ver os $n no mapa',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11),
                      ),
                  ],
                ),
              ),
              if (_filtro.quantidadeAtivos > 0)
                GestureDetector(
                  onTap: () => setState(() => _filtro = const PostFilter()),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      'Limpar filtros',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                )
              else if (tocavel)
                const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avisoErro() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Não foi possível carregar os posts.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(onPressed: _tentarDeNovo, child: const Text('Tentar de novo')),
        ],
      ),
    );
  }

  Widget _controles() {
    final filtros = _filtro.quantidadeAtivos;
    return Column(
      children: [
        _botaoRedondo(
          icone: _localizando ? null : Icons.my_location,
          dica: 'Minha localização',
          onTap: _localizando ? null : _irParaMinhaLocalizacao,
        ),
        const SizedBox(height: 8),
        Badge(
          isLabelVisible: filtros > 0,
          label: Text('$filtros'),
          backgroundColor: AppColors.primary,
          child: _botaoRedondo(
            icone: Icons.filter_list,
            dica: 'Filtros',
            onTap: _abrirFiltros,
          ),
        ),
        const SizedBox(height: 8),
        _botaoRedondo(
          icone: _camada == MapType.normal ? Icons.satellite_alt : Icons.map,
          dica: _camada == MapType.normal ? 'Ver satélite' : 'Ver mapa',
          onTap: _alternarCamada,
        ),
      ],
    );
  }

  /// Botão redondo branco. Com [icone] nulo mostra um carregamento.
  Widget _botaoRedondo(
      {IconData? icone, required String dica, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        tooltip: dica,
        onPressed: onTap,
        icon: icone == null
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icone, color: AppColors.onSurface, size: 20),
      ),
    );
  }

  Widget _legenda() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (tipo, rotulo) in const [
            (PostType.lost, 'Perdido (urgente)'),
            (PostType.sighted, 'Avistado na região'),
            (PostType.found, 'Sob cuidados / achado'),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: tipo.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(rotulo,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _botaoCriar(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'mapCreateFab',
      onPressed: () => Navigator.pushNamed(context, AppRoutes.createPost),
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Criar postagem',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Resumo do post ao tocar no marcador, com o botão "Ver detalhes".
class _ResumoPost extends StatelessWidget {
  final PostModel post;
  const _ResumoPost({required this.post});

  @override
  Widget build(BuildContext context) {
    final cor = post.type.color;
    final nome = post.petName.isNotEmpty && post.petName != 'Sem nome'
        ? post.petName
        : 'Pet sem nome';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: ColoredBox(
                      color: AppColors.background,
                      child: PetImage(url: post.photoUrl, iconSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          _etiqueta(post.type.label.toUpperCase(), cor),
                          if (post.isResolved)
                            _etiqueta('RESOLVIDO', AppColors.tagFound),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        nome,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [post.species, post.breed, ...post.colors].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: AppColors.primary, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              post.lastSeenAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              post.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(MaterialPageRoute(
                    builder: (_) => DetailScreen(post: post)));
              },
              child: const Text('Ver detalhes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _etiqueta(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.2)),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

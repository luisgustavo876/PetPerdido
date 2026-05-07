import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../core/app_routes.dart';
import '../../models/post_model.dart';
import '../../widgets/pet_post_card.dart';

/// Aba do Mapa.
/// Exibe os posts de pets perdidos/achados/avistados como marcadores coloridos.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;

  /// Posição inicial da câmera — Itapetininga, SP
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(AppConstants.defaultLat, AppConstants.defaultLng),
    zoom: 13.5,
  );

  /// Conjunto de marcadores gerados a partir dos posts
  late final Set<Marker> _markers;

  @override
  void initState() {
    super.initState();
    _markers = _buildMarkersFromPosts(mockPosts);
  }

  /// Converte uma lista de PostModel em marcadores do Google Maps.
  Set<Marker> _buildMarkersFromPosts(List<PostModel> posts) {
    return posts.map((post) {
      return Marker(
        markerId: MarkerId(post.id),
        position: LatLng(post.latitude, post.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(_hueForType(post.type)),
        infoWindow: InfoWindow(
          title: _titleForPost(post),
          snippet: post.lastSeenAddress,
          onTap: () => _showPostBottomSheet(post),
        ),
        onTap: () {
          // Abre o InfoWindow e aguarda um toque nele para o BottomSheet
        },
      );
    }).toSet();
  }

  /// Retorna o hue do marcador de acordo com o tipo do post.
  double _hueForType(PostType type) {
    switch (type) {
      case PostType.lost:
        return BitmapDescriptor.hueRed;
      case PostType.found:
        return BitmapDescriptor.hueGreen;
      case PostType.sighted:
        return BitmapDescriptor.hueOrange;
    }
  }

  String _titleForPost(PostModel post) {
    final emoji = post.type == PostType.lost
        ? '🔴'
        : post.type == PostType.found
            ? '🟢'
            : '🟠';
    final name =
        post.petName.isNotEmpty && post.petName != 'Sem nome' ? post.petName : 'Pet';
    return '$emoji ${post.type.label} — $name';
  }

  void _showPostBottomSheet(PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostBottomSheet(post: post),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PetPerdido'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Centralizar mapa',
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(_initialPosition),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa principal
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: _markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // Banner de alerta no topo
          _buildAlertBanner(),

          // Legenda dos marcadores
          _buildLegend(),

          // Botão de criar post
          _buildCreatePostButton(context),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    final lostCount =
        mockPosts.where((p) => p.type == PostType.lost).length;
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_active,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Há $lostCount pet${lostCount != 1 ? 's' : ''} perdido${lostCount != 1 ? 's' : ''} na sua região!',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Positioned(
      top: 70,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 6),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _legendItem(AppColors.tagLost, 'Perdido'),
            const SizedBox(height: 4),
            _legendItem(AppColors.tagFound, 'Achado'),
            const SizedBox(height: 4),
            _legendItem(AppColors.tagSighted, 'Avistado'),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCreatePostButton(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 16,
      child: FloatingActionButton.extended(
        heroTag: 'mapFab',
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createPost),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Criar Post',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// BottomSheet com o resumo do post ao tocar em um marcador.
class _PostBottomSheet extends StatelessWidget {
  final PostModel post;
  const _PostBottomSheet({required this.post});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Card do post (reutiliza o widget existente)
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    PetPostCard(
                      post: post,
                      onChatTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chat — próxima iteração'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

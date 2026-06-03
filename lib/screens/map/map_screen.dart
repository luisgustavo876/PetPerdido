import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../core/app_routes.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../feed/detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(AppConstants.defaultLat, AppConstants.defaultLng),
    zoom: 13.8,
  );

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers(List<PostModel> posts) {
    return posts.map((post) {
      return Marker(
        markerId: MarkerId(post.id),
        position: LatLng(post.latitude, post.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(_hueForType(post.type)),
        onTap: () => _showPostBottomSheet(post),
      );
    }).toSet();
  }

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

  void _showPostBottomSheet(PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostBottomSheet(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<PostModel>>(
        stream: PostService.postsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data ?? [];
          final markers = _buildMarkers(posts);
          final lostCount = posts.where((p) => p.type == PostType.lost).length;

          return Stack(
            children: [
              // GoogleMap real e funcional
              GoogleMap(
                initialCameraPosition: _initialPosition,
                markers: markers,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
              ),

              // Banner superior flutuante com gradiente
              Positioned(
                top: 14,
                left: 16,
                right: 16,
                child: _buildGradientAlertBanner(lostCount),
              ),

              // Controles laterais do mapa
              Positioned(
                right: 16,
                top: 96,
                child: _buildMapControls(),
              ),

              // Legenda suspensa
              Positioned(
                left: 16,
                bottom: 84,
                child: _buildLegend(),
              ),

              // FAB estendido para criar postagem
              Positioned(
                right: 16,
                bottom: 20,
                child: _buildCreatePostFab(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGradientAlertBanner(int count) {
    return Container(
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
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ALERTA DE SEGURANÇA',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Há $count pet${count != 1 ? 's' : ''} perdido${count != 1 ? 's' : ''} na sua região de busca!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 12),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Column(
      children: [
        _controlButton(Icons.my_location, 'Localizar', () {
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(_initialPosition),
          );
        }),
        const SizedBox(height: 10),
        _controlButton(Icons.filter_list, 'Filtros', () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aplicar filtros avançados de busca...')),
          );
        }),
        const SizedBox(height: 10),
        _controlButton(Icons.layers, 'Camadas', () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alternar satélite / mapa padrão...')),
          );
        }),
      ],
    );
  }

  Widget _controlButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.onSurface, size: 20),
        onPressed: onTap,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendItem(AppColors.tagLost, 'Perdido (Urgente)'),
          const SizedBox(height: 6),
          _legendItem(AppColors.tagSighted, 'Avistado na região'),
          const SizedBox(height: 6),
          _legendItem(AppColors.tagFound, 'Sob cuidados/Achado'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCreatePostFab(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'mapCreateFab',
      onPressed: () => Navigator.pushNamed(context, AppRoutes.createPost),
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add, color: Colors.white),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      label: const Text(
        'Criar Postagem',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

class _PostBottomSheet extends StatelessWidget {
  final PostModel post;
  const _PostBottomSheet({required this.post});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(post.type);

    return DraggableScrollableSheet(
      initialChildSize: 0.44,
      minChildSize: 0.3,
      maxChildSize: 0.6,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 16),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagem circular grande do pet
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey[100],
                      child: post.photoUrl != null
                          ? Image.asset(post.photoUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.pets, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusColor.withOpacity(0.2)),
                              ),
                              child: Text(
                                post.type.label.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (post.points > 0)
                              Row(
                                children: [
                                  const Icon(Icons.stars, color: Colors.amber, size: 14),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${post.points} pts',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          post.petName.isNotEmpty && post.petName != 'Sem nome' ? post.petName : 'Sem Nome',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.primary, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                post.lastSeenAddress,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              // Tags
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: post.traits.take(3).map((trait) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      trait,
                      style: const TextStyle(fontSize: 10, color: Colors.black87),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(post: post),
                          ),
                        );
                      },
                      child: const Text('Ver Detalhes', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(post: post),
                          ),
                        );
                      },
                      child: const Text(
                        'Ajudar Pet',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(PostType type) {
    switch (type) {
      case PostType.lost:
        return AppColors.tagLost;
      case PostType.found:
        return AppColors.tagFound;
      case PostType.sighted:
        return AppColors.tagSighted;
    }
  }
}

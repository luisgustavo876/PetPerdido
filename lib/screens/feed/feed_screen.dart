import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../models/post_model.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../widgets/pet_post_card.dart';
import 'detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _searchQuery = '';
  String _activeFilter = 'todos';

  List<PostModel> _getFilteredPosts(List<PostModel> posts) {
    var list = posts;

    if (_activeFilter == 'lost') {
      list = list.where((p) => p.type == PostType.lost).toList();
    } else if (_activeFilter == 'sighted') {
      list = list.where((p) => p.type == PostType.sighted).toList();
    } else if (_activeFilter == 'found') {
      list = list.where((p) => p.type == PostType.found).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((p) {
        return p.petName.toLowerCase().contains(query) ||
            p.breed.toLowerCase().contains(query) ||
            p.description.toLowerCase().contains(query) ||
            p.traits.any((t) => t.toLowerCase().contains(query)) ||
            p.lastSeenAddress.toLowerCase().contains(query);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<PostModel>>(
        stream: PostService.postsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar os posts.'));
          }

          final posts = snapshot.data ?? [];
          final filteredPosts = _getFilteredPosts(posts);

          return Column(
            children: [
              _buildSearchSection(),
              Expanded(
                child: filteredPosts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 32),
                        itemCount: filteredPosts.length,
                        itemBuilder: (context, index) {
                          return PetPostCard(
                            post: filteredPosts[index],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailScreen(
                                    post: filteredPosts[index],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchSection() {
    final filters = [
      {'id': 'todos', 'label': 'Todos'},
      {'id': 'lost', 'label': 'Perdidos'},
      {'id': 'sighted', 'label': 'Avistados'},
      {'id': 'found', 'label': 'Achados'},
    ];

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          // Search bar no estilo Inter
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.search,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Buscar pets próximos...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textTertiary,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              fillColor: Colors.transparent,
                              filled: false,
                            ),
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Botão de filtro avançado
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Filtros avançados em breve')),
                    );
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filtros por categoria
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final filter = filters[index];
                final id = filter['id']!;
                final isSelected = _activeFilter == id;

                return GestureDetector(
                  onTap: () => setState(() => _activeFilter = id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      filter['label']!,
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Linha divisória
          Container(height: 1, color: AppColors.divider),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.search_off,
                size: 36, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhum pet encontrado',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tente outros termos ou altere os filtros.',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/post_model.dart';
import '../../models/app_state.dart';
import '../../widgets/pet_post_card.dart';
import 'detail_screen.dart';
import '../chat/chat_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final AppState _appState = AppState();
  String _searchQuery = '';
  String _activeFilter = 'todos'; // todos, lost, sighted, found

  List<PostModel> _getFilteredPosts(List<PostModel> posts) {
    var list = posts;

    // Filtrar por aba
    if (_activeFilter == 'lost') {
      list = list.where((p) => p.type == PostType.lost).toList();
    } else if (_activeFilter == 'sighted') {
      list = list.where((p) => p.type == PostType.sighted).toList();
    } else if (_activeFilter == 'found') {
      list = list.where((p) => p.type == PostType.found).toList();
    }

    // Filtrar por busca
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: ListenableBuilder(
        listenable: _appState,
        builder: (context, _) {
          final posts = _appState.posts;
          final filteredPosts = _getFilteredPosts(posts);

          return Column(
            children: [
              _buildSearchHeader(),
              _buildFilterChips(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    // Banner de Match de Inteligência Artificial
                    _buildIaMatchBanner(context),
                    
                    if (filteredPosts.isEmpty)
                      _buildEmptyState()
                    else
                      ...filteredPosts.map((post) {
                        return PetPostCard(
                          post: post,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(post: post),
                              ),
                            );
                          },
                        );
                      }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Buscar raça, cor, características...',
                        border: InputBorder.none,
                        isDense: true,
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: AppColors.primary, size: 18),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filtros avançados (distância, espécie)...')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'id': 'todos', 'label': 'Todos os Pets'},
      {'id': 'lost', 'label': 'Perdidos'},
      {'id': 'sighted', 'label': 'Avistados'},
      {'id': 'found', 'label': 'Achados'},
    ];

    return Container(
      height: 46,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final id = filter['id'] as String;
          final isSelected = _activeFilter == id;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                filter['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.grey[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey[200]!),
              showCheckmark: false,
              onSelected: (val) {
                if (val) {
                  setState(() => _activeFilter = id);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildIaMatchBanner(BuildContext context) {
    // Apenas mostrar se estivermos na aba geral ou perdidos, simulando o match da Laura
    if (_activeFilter != 'todos' && _activeFilter != 'lost') return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showIaMatchDialog(context),
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2E7D32), // Verde Floresta Premium
              Color(0xFF4CAF50),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECONHECIMENTO DE IA ACTIVO',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '2 novos matches possíveis para Laura!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Nossa IA encontrou semelhanças em avistamentos.',
                    style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum pet encontrado',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSurface),
          ),
          const SizedBox(height: 6),
          const Text(
            'Experimente buscar por outros termos ou alterar os filtros ativos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showIaMatchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone e Título
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.psychology, color: Colors.green, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Match Inteligente de IA',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Comparamos os traços e fotos de Laura com avistamentos próximos em Itapetininga e encontramos alta compatibilidade!',
                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 20),

                // Comparativo Lado a Lado
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset('assets/images/cat-laura.jpg', height: 100, width: double.infinity, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 6),
                          const Text('Gata Laura', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const Text('Seu Pet', style: TextStyle(fontSize: 9, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '86%',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset('assets/images/dog_sighted.png', height: 100, width: double.infinity, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 6),
                          const Text('Gata avistada', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const Text('No Jd. Marabá', style: TextStyle(fontSize: 9, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Detalhe dos fatores de match
                _matchFactorRow('Pelagem Siamesa Creme', 1.0),
                _matchFactorRow('Olhos Azuis Intensos', 0.92),
                _matchFactorRow('Sem Coleira identificada', 1.0),
                _matchFactorRow('Localização aproximada (2.3 km)', 0.72),

                const SizedBox(height: 24),
                // Ações do Dialog
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Voltar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                          final lauraPost = _appState.posts.firstWhere((p) => p.id == '1');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(post: lauraPost),
                            ),
                          );
                        },
                        child: const Text(
                          'Abrir Chat',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _matchFactorRow(String factor, double score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(factor, style: const TextStyle(fontSize: 11, color: Colors.black87)),
          Row(
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: score,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${(score * 100).toInt()}%',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          )
        ],
      ),
    );
  }
}

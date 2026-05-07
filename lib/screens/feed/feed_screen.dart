import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../models/post_model.dart';
import '../../widgets/pet_post_card.dart';

/// Aba do Feed.
/// Exibe lista de postagens usando dados mockados.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<PostModel> _filteredPosts(PostType? type) {
    if (type == null) return mockPosts;
    return mockPosts.where((p) => p.type == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PetPerdido'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Todas'),
            Tab(text: 'Perdidos'),
            Tab(text: 'Achados'),
            Tab(text: 'Avistados'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.createPost),
            tooltip: 'Criar postagem',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostList(null),
          _buildPostList(PostType.lost),
          _buildPostList(PostType.found),
          _buildPostList(PostType.sighted),
        ],
      ),
    );
  }

  Widget _buildPostList(PostType? filter) {
    final posts = _filteredPosts(filter);

    if (posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text(
              'Nenhuma postagem nesta categoria',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return PetPostCard(
          post: post,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Abrindo post de ${post.userName}...'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          onChatTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chat — próxima iteração'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        );
      },
    );
  }
}

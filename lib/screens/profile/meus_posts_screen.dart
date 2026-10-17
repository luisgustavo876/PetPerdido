import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../widgets/pet_post_card.dart';
import '../feed/detail_screen.dart';

/// "Meus posts", com marcar como resolvido e excluir.
class MeusPostsScreen extends StatefulWidget {
  const MeusPostsScreen({super.key});

  @override
  State<MeusPostsScreen> createState() => _MeusPostsScreenState();
}

class _MeusPostsScreenState extends State<MeusPostsScreen> {
  late Future<List<PostModel>> _posts;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    final uid = AuthService.currentUser?.uid;
    _posts = uid == null ? Future.value(const []) : PostService.postsDoAutor(uid);
  }

  void _recarregar() => setState(_carregar);

  Future<bool> _confirmar(String titulo, String texto, String botao) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
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

  Future<void> _executar(Future<void> Function() acao, String sucesso) async {
    try {
      await acao();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(sucesso)));
      _recarregar();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível concluir. Tente novamente.')));
    }
  }

  Future<void> _resolver(PostModel p) async {
    if (!await _confirmar('Marcar como resolvido?',
        'O post sai do mapa e do feed.', 'Marcar')) {
      return;
    }
    await _executar(() => PostService.marcarResolvido(p.id), 'Post marcado como resolvido.');
  }

  Future<void> _excluir(PostModel p) async {
    if (!await _confirmar('Excluir este post?',
        'O post, os avistamentos e as fotos serão apagados.', 'Excluir')) {
      return;
    }
    await _executar(() => PostService.excluirPost(p), 'Post excluído.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Meus posts')),
      body: FutureBuilder<List<PostModel>>(
        future: _posts,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Não foi possível carregar.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: _recarregar, child: const Text('Tentar de novo')),
                ],
              ),
            );
          }
          final posts = snapshot.data ?? const <PostModel>[];
          if (posts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Você ainda não publicou nenhum post.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              _recarregar();
              await _posts;
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: posts.length,
              itemBuilder: (context, i) {
                final p = posts[i];
                return Column(
                  children: [
                    PetPostCard(
                      post: p,
                      onTap: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => DetailScreen(post: p)));
                        _recarregar();
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!p.isResolved)
                            TextButton.icon(
                              onPressed: () => _resolver(p),
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Marcar como resolvido'),
                            ),
                          TextButton.icon(
                            onPressed: () => _excluir(p),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Excluir'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

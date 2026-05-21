import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/post_model.dart';
import '../screens/chat/chat_screen.dart';

class PetPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;

  const PetPostCard({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(post.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do Tutor
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: post.ownerAvatar != null ? NetworkImage(post.ownerAvatar!) : null,
                    backgroundColor: AppColors.primaryLight,
                    child: post.ownerAvatar == null
                        ? Text(post.userName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.userName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.verified, color: Colors.teal[600], size: 12),
                          ],
                        ),
                        Text(
                          _timeAgo(post.createdAt),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                ],
              ),
            ),

            // Imagem do Pet com cantos arredondados e tags
            if (post.photoUrl != null)
              Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: AssetImage(post.photoUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    // Gradiente escuro no rodapé da imagem para contraste
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black45],
                          ),
                        ),
                      ),
                    ),
                    // Recompensa
                    if (post.points > 0)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stars, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${post.points} pts',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Conteúdo do Post
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        post.petName.isNotEmpty && post.petName != 'Sem nome' ? post.petName : 'Pet Sem Nome',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.primary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            post.lastSeenAddress,
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Especificações breves
                  Row(
                    children: [
                      _briefTag(post.species),
                      const SizedBox(width: 6),
                      _briefTag(post.breed),
                      const SizedBox(width: 6),
                      _briefTag(post.size),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF2F2F2)),
                  const SizedBox(height: 10),
                  // Rodapé interativo
                  Row(
                    children: [
                      // Ajudantes
                      Icon(Icons.people_outline, color: Colors.grey[600], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${post.helpersCount} ajudando',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      // Avistamentos
                      Icon(Icons.visibility_outlined, color: Colors.grey[600], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${post.sightingsCount} avistados',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      // Botão de Chat Direto
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(post: post),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.primary),
                        label: const Text(
                          'Conversar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          backgroundColor: AppColors.primary.withOpacity(0.06),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _briefTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10.5, color: Colors.black87, fontWeight: FontWeight.w600),
      ),
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

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Há ${diff.inHours}h';
    return 'Há ${diff.inDays}d';
  }
}

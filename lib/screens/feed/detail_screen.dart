import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../models/post_model.dart';
import '../../core/dados_globais.dart';
import '../../services/post_service.dart';
import '../chat/chat_screen.dart';

class DetailScreen extends StatefulWidget {
  final PostModel post;

  const DetailScreen({super.key, required this.post});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late PostModel _currentPost;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: AppColors.surface,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(context, _currentPost),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(_currentPost),
                      const SizedBox(height: 20),
                      _buildSpecGrid(_currentPost),
                      const SizedBox(height: 24),
                      if (_currentPost.traits.isNotEmpty) ...[
                        _sectionTitle('Características'),
                        const SizedBox(height: 10),
                        _buildTraits(_currentPost),
                        const SizedBox(height: 24),
                      ],
                      _sectionTitle('Descrição'),
                      const SizedBox(height: 10),
                      Text(
                        _currentPost.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _sectionTitle('Tutor'),
                      const SizedBox(height: 10),
                      _buildTutorCard(context, _currentPost),
                      const SizedBox(height: 28),
                      _sectionTitle(
                          'Avistamentos (${_currentPost.sightingsCount})'),
                      const SizedBox(height: 12),
                      _buildTimeline(_currentPost),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildActions(context, _currentPost),
        );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildHero(BuildContext context, PostModel post) {
    return Stack(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          color: AppColors.background,
          child: post.photoUrl != null
              ? _buildHeroImage(post.photoUrl!)
              : const Center(
                  child: Icon(Icons.pets, size: 80, color: AppColors.textTertiary)),
        ),
        // Gradiente topo para botões
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 100,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black45, Colors.transparent],
              ),
            ),
          ),
        ),
        // Botão voltar
        Positioned(
          top: 44, left: 16,
          child: _iconButton(Icons.arrow_back, () => Navigator.pop(context)),
        ),
        // Botões direita
        Positioned(
          top: 44, right: 16,
          child: Row(
            children: [
              _iconButton(Icons.share_outlined, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copiado!')),
                );
              }),
              const SizedBox(width: 8),
              _iconButton(Icons.favorite_border, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Adicionado aos favoritos!')),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.onSurface),
      ),
    );
  }

  Widget _buildHeader(PostModel post) {
    final statusColor = _statusColor(post.type);
    final statusSurface = _statusSurface(post.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                post.petName.isNotEmpty && post.petName != 'Sem nome'
                    ? post.petName
                    : 'Pet sem nome',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                post.type.label,
                style: GoogleFonts.inter(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                post.lastSeenAddress,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            if (post.points > 0) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: Colors.amber, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '${post.points} pts',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF92400E),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSpecGrid(PostModel post) {
    return Row(
      children: [
        Expanded(child: _specItem('Espécie', post.species, Icons.pets_outlined)),
        const SizedBox(width: 10),
        Expanded(child: _specItem('Raça', post.breed, Icons.category_outlined)),
        const SizedBox(width: 10),
        Expanded(child: _specItem('Porte', post.size, Icons.straighten)),
        const SizedBox(width: 10),
        Expanded(child: _specItem('Sexo', post.sex, Icons.wc_outlined)),
      ],
    );
  }

  Widget _specItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, color: AppColors.textTertiary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTraits(PostModel post) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: post.traits.map((trait) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            trait,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTutorCard(BuildContext context, PostModel post) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primarySurface,
            backgroundImage: post.ownerAvatar != null
                ? NetworkImage(post.ownerAvatar!)
                : null,
            child: post.ownerAvatar == null
                ? Text(post.userName[0].toUpperCase(),
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 16))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      post.userName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified,
                        color: Colors.teal, size: 14),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Membro desde 2024 · 5 ajudas',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatScreen(post: post)),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  color: AppColors.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(PostModel post) {
    final sightings = [
      {
        'date': 'Há 2 horas',
        'address': 'Próximo ao Supermercado Avenida, Vila Barth',
        'reporter': 'Juliana M.',
        'desc': 'Vi um gatinho idêntico na calçada. Correu ao me aproximar.',
      },
      if (post.sightingsCount >= 2)
        {
          'date': 'Ontem, 19:30',
          'address': 'Rua Bernardino de Campos, Vila Barth',
          'reporter': 'Marcos A.',
          'desc': 'Estava debaixo de um carro. Miando bastante.',
        },
      if (post.sightingsCount >= 3)
        {
          'date': 'Agora mesmo',
          'address': 'Avistamento recente registrado',
          'reporter': 'Você',
          'desc': 'Avistamento adicionado nas proximidades.',
        },
    ];

    if (sightings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Nenhum avistamento registrado ainda.',
          style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sightings.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final s = sightings[index];
        final isLast = index == sightings.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1.5,
                    height: 72,
                    color: AppColors.divider,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s['date']!,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        Text(s['reporter']!,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textTertiary)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(s['address']!,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface)),
                    const SizedBox(height: 3),
                    Text(s['desc']!,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActions(BuildContext context, PostModel post) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatScreen(post: post)),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text('Chat'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 50),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showEuViSheet(context, post),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('Eu Vi este Pet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEuViSheet(BuildContext context, PostModel post) {
    final addressController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Registrar Avistamento',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sua informação ajuda o tutor. Você ganha +15 pontos.',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                Text('Onde você o viu?',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.onSurface)),
                const SizedBox(height: 8),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    hintText: 'Ex: Próximo à praça central...',
                    prefixIcon: const Icon(Icons.location_on_outlined,
                        color: AppColors.primary, size: 18),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Detalhes (opcional)',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.onSurface)),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Parecia assustado, correu para um beco...',
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Foto anexada!')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined,
                            color: AppColors.textTertiary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Anexar foto do pet',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (addressController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Informe a localização!')),
                        );
                        return;
                      }
                      
                      // Chama o PostService diretamente
                      PostService.incrementSighting(post.id);
                      DadosGlobais.pontosUsuario += 15;
                      
                      setState(() {
                        _currentPost = _currentPost.copyWith(
                          sightingsCount: _currentPost.sightingsCount + 1,
                        );
                      });

                      Navigator.pop(context);
                      _showSuccessDialog(context);
                    },
                    child: const Text('Registrar e Ajudar'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Color(0xFF16A34A), size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  'Obrigado!',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'O tutor foi notificado sobre o avistamento.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    '+15 pontos ganhos!',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF92400E),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Ótimo!'),
                  ),
                ),
              ],
            ),
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

  Color _statusSurface(PostType type) {
    switch (type) {
      case PostType.lost:
        return AppColors.tagLostSurface;
      case PostType.found:
        return AppColors.tagFoundSurface;
      case PostType.sighted:
        return AppColors.tagSightedSurface;
    }
  }

  /// Exibe imagem hero de rede ou asset local.
  Widget _buildHeroImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 300,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image, size: 80, color: AppColors.textTertiary),
        ),
      );
    }
    return Image.asset(url, fit: BoxFit.cover);
  }
}

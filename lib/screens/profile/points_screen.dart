import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../models/app_state.dart';

/// Tela de Pontos e Recompensas.
/// Versão simplificada para o protótipo do TCC.
class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});

  // Lista de recompensas disponíveis
  static const List<Map<String, dynamic>> _rewards = [
    {
      'id': 'banho_gratis',
      'title': 'Banho Completo',
      'partner': 'PetShop Amigão',
      'points': 100,
      'icon': Icons.shower_outlined,
      'color': Color(0xFF2563EB),
      'surface': Color(0xFFEFF6FF),
    },
    {
      'id': 'saco_racao',
      'title': 'Saco de Ração 15kg',
      'partner': 'AgroPet Silva',
      'points': 150,
      'icon': Icons.backpack_outlined,
      'color': Color(0xFFD97706),
      'surface': Color(0xFFFFFBEB),
    },
    {
      'id': 'consulta_vet',
      'title': 'Consulta Veterinária',
      'partner': 'Clínica ProBicho',
      'points': 250,
      'icon': Icons.medical_services_outlined,
      'color': Color(0xFF16A34A),
      'surface': Color(0xFFF0FDF4),
    },
    {
      'id': 'castracao',
      'title': 'Castração Solidária',
      'partner': 'Hospital Vet Municipal',
      'points': 300,
      'icon': Icons.pets_outlined,
      'color': Color(0xFF7C3AED),
      'surface': Color(0xFFF5F3FF),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final points = appState.userPoints;
        final redeemed = appState.redeemedRewards;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card principal de pontos
              _buildPointsCard(points),
              const SizedBox(height: 16),

              // Barra de progresso de nível
              _buildLevelCard(points),
              const SizedBox(height: 28),

              // Título seção recompensas
              Text(
                'Recompensas',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Use seus pontos em parceiros locais de Itapetininga.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Grid de recompensas
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: _rewards.length,
                itemBuilder: (context, index) {
                  return _buildRewardCard(
                    context,
                    _rewards[index],
                    points,
                    redeemed,
                    appState,
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPointsCard(int points) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -12,
            bottom: -12,
            child: Opacity(
              opacity: 0.08,
              child: Icon(Icons.pets, size: 100, color: Colors.white),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SEUS PONTOS',
                style: GoogleFonts.inter(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$points',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'pts',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: Colors.white, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      'Cidadão Pet Ativo · Itapetininga',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(int points) {
    const int levelMax = 500;
    final double percent = (points / levelMax).clamp(0.0, 1.0);
    final int remaining = (levelMax - points).clamp(0, levelMax);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nível 3 · Vizinho Ajudante',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                '$points / $levelMax',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: AppColors.background,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Faltam $remaining pts para o Nível 4.',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(
    BuildContext context,
    Map<String, dynamic> reward,
    int points,
    List<String> redeemed,
    AppState appState,
  ) {
    final id = reward['id'] as String;
    final cost = reward['points'] as int;
    final isRedeemed = redeemed.contains(id);
    final canRedeem = points >= cost && !isRedeemed;
    final color = reward['color'] as Color;
    final surface = reward['surface'] as Color;

    return Opacity(
      opacity: isRedeemed ? 0.55 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: canRedeem
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.divider,
            width: canRedeem ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(reward['icon'] as IconData, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              reward['partner'] as String,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              reward['title'] as String,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: Colors.amber, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      '$cost',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: canRedeem
                      ? () => _redeem(
                          context, id, reward['title'] as String, cost, appState)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isRedeemed
                          ? AppColors.background
                          : (canRedeem
                              ? AppColors.primary
                              : AppColors.background),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      isRedeemed ? 'Usado' : 'Resgatar',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isRedeemed
                            ? AppColors.textTertiary
                            : (canRedeem
                                ? Colors.white
                                : AppColors.textTertiary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _redeem(BuildContext context, String id, String title, int cost,
      AppState appState) {
    final success = appState.redeemReward(id, cost);
    if (!success) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              const Text(
                'Resgate realizado!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              const Text(
                'Apresente o código no parceiro para utilizar o benefício.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Column(
                  children: [
                    Text(
                      'CÓDIGO DE RESGATE',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'PET-HELP-5897',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

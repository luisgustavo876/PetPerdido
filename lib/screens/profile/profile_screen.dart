import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../services/auth_service.dart';

/// Tela de Perfil do usuário.
/// Esqueleto visual — dados reais virão do Firebase nas próximas iterações.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildStats(),
          const SizedBox(height: 24),
          _buildSection('Minhas Postagens', Icons.feed_outlined, () {}),
          _buildSection('Configurações', Icons.settings_outlined, () {}),
          _buildSection('Sobre o PetPerdido', Icons.info_outline, () {}),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout, color: AppColors.tagLost),
            label: const Text(
              'Sair da conta',
              style: TextStyle(color: AppColors.tagLost),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.tagLost),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryLight,
          ),
          child: const Icon(Icons.person, size: 50, color: AppColors.primaryDark),
        ),
        const SizedBox(height: 12),
        const Text(
          'Nome do Usuário',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'usuario@email.com',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: AppColors.primaryLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '80 pontos',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _buildStatItem('2', 'Posts\npublicados'),
        _buildDivider(),
        _buildStatItem('1', 'Pet\nencontrado'),
        _buildDivider(),
        _buildStatItem('5', 'Avistamentos\nreportados'),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 40, width: 1, color: AppColors.divider);
  }

  Widget _buildSection(String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.signOut(); // Firebase signOut → AuthGate redireciona
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tagLost,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

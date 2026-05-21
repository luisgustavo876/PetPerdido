import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/app_state.dart';
import 'report_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppState _appState = AppState();
  double _radarRadius = 5.0; // 5 km padrão
  bool _pushNotifications = true;
  bool _radarActive = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        final points = _appState.userPoints;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: const Text('Configurações & Perfil'),
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.onSurface,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: Colors.grey[200], height: 1),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(points),
                const SizedBox(height: 24),
                _buildSectionTitle('Alertas & Radar'),
                const SizedBox(height: 12),
                _buildRadarCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('Preferências'),
                const SizedBox(height: 12),
                _buildPreferencesCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('Parcerias de Apoio'),
                const SizedBox(height: 12),
                _buildNGOsCard(),
                const SizedBox(height: 32),
                _buildSupportButton(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildProfileCard(int points) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: const NetworkImage(
                      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
                    ),
                    backgroundColor: Colors.grey[200],
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Carol Mendes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Tutor Premium',
                            style: TextStyle(
                              color: Colors.teal[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'carol.mendes@email.com',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stars, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '$points pts',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.pets, color: AppColors.primary, size: 14),
                              SizedBox(width: 4),
                              Text(
                                '12 Ajudas',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Identidade Verificada (LGPD)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              TextButton(
                onPressed: () => _showVerificationDialog(context),
                child: const Text('Ver Detalhes', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRadarCard() {
    final int estimatedNeighbors = (_radarRadius * 250).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            value: _radarActive,
            onChanged: (val) => setState(() => _radarActive = val),
            title: const Text('Modo Radar Ativo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: const Text('Receba notificações se novos pets sumirem na sua região.', style: TextStyle(fontSize: 12)),
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
          ),
          if (_radarActive) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Raio do Radar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  '${_radarRadius.toStringAsFixed(1)} km',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15),
                ),
              ],
            ),
            Slider(
              value: _radarRadius,
              min: 1.0,
              max: 10.0,
              divisions: 18,
              label: '${_radarRadius.toStringAsFixed(1)} km',
              activeColor: AppColors.primary,
              inactiveColor: Colors.grey[200],
              onChanged: (val) => setState(() => _radarRadius = val),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_alt, color: Colors.teal, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estimativa de ~$estimatedNeighbors vizinhos vizinhos alertados nesta área!',
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _pushNotifications,
            onChanged: (val) => setState(() => _pushNotifications = val),
            title: const Text('Notificações Push', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            activeColor: AppColors.primary,
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          SwitchListTile(
            value: _darkMode,
            onChanged: (val) {
              // Fica estático e inativo conforme decisões de design
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tema Escuro indisponível nesta versão (apenas Tema Claro)')),
              );
            },
            title: const Text('Tema Escuro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Indisponível (Em breve)', style: TextStyle(fontSize: 11)),
            activeColor: Colors.grey,
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          ListTile(
            title: const Text('Idioma', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            trailing: const Text('Português (BR)', style: TextStyle(color: Colors.grey, fontSize: 13)),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildNGOsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          _ngoItem('ONG UPA Itapetininga', 'Parceira oficial de resgate animal municipal.', Icons.healing),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          _ngoItem('Grupo Patas Solidárias', 'Rede de lares temporários voluntários.', Icons.volunteer_activism),
        ],
      ),
    );
  }

  Widget _ngoItem(String name, String desc, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
      ],
    );
  }

  Widget _buildSupportButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const ReportSheet(),
          );
        },
        icon: const Icon(Icons.support_agent),
        label: const Text(
          'Suporte & Reportar Problemas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  void _showVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.verified, color: Colors.teal),
              SizedBox(width: 8),
              Text('Perfil Verificado', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Sua conta está associada com CPF e número de celular verificados. Seus posts ganham prioridade e badges de segurança para evitar fake news.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/pet_options.dart';
import '../../services/pontos_service.dart';

/// Meus resgates (users/{uid}/redemptions), com o código de cada voucher.
class MeusResgatesScreen extends StatefulWidget {
  const MeusResgatesScreen({super.key});

  @override
  State<MeusResgatesScreen> createState() => _MeusResgatesScreenState();
}

class _MeusResgatesScreenState extends State<MeusResgatesScreen> {
  late Stream<List<Resgate>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = PontosService.resgatesStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus resgates')),
      body: StreamBuilder<List<Resgate>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: () =>
                    setState(() => _stream = PontosService.resgatesStream()),
                child: const Text('Não foi possível carregar. Tentar de novo'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final lista = snapshot.data!;
          if (lista.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Nenhum resgate ainda.\nJunte pontos e troque na aba Pontos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            itemBuilder: (context, i) {
              final r = lista[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(r.titulo,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                        Text('-${r.custo} pts',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Resgatado em ${formatarDataHora(r.createdAt)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    SelectableText(
                      r.codigo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

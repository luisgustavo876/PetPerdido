import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../services/pontos_service.dart';

/// Histórico de pontos (users/{uid}/pointsLog).
class HistoricoPontosScreen extends StatefulWidget {
  const HistoricoPontosScreen({super.key});

  @override
  State<HistoricoPontosScreen> createState() => _HistoricoPontosScreenState();
}

class _HistoricoPontosScreenState extends State<HistoricoPontosScreen> {
  late Stream<List<LancamentoPontos>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = PontosService.historicoStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de pontos')),
      body: StreamBuilder<List<LancamentoPontos>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: () =>
                    setState(() => _stream = PontosService.historicoStream()),
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
                  'Você ainda não ganhou pontos.\nPublique um "Achei" ou '
                  '"Avistei", ou registre "Eu vi este pet".',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: lista.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final l = lista[i];
              final positivo = l.delta >= 0;
              return ListTile(
                leading: Icon(
                  positivo ? Icons.add_circle_outline : Icons.remove_circle_outline,
                  color: positivo ? AppColors.tagFound : AppColors.primary,
                ),
                title: Text(l.motivo),
                subtitle:
                    Text(Formatters.tempoRelativo(l.createdAt, DateTime.now())),
                trailing: Text(
                  '${positivo ? '+' : ''}${l.delta} pts',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: positivo ? AppColors.tagFound : AppColors.primary,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

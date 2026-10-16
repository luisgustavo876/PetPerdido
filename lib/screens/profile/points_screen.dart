import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../core/recompensas.dart';
import '../../services/pontos_service.dart';
import 'historico_pontos_screen.dart';
import 'meus_resgates_screen.dart';

/// Pontos e recompensas: saldo real (users/{uid}.points), nível, como ganhar
/// e catálogo de recompensas de exemplo com resgate.
class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  /// Stream único da tela, criado no initState.
  late Stream<int> _saldoStream;
  String? _resgatando; // id da recompensa sendo resgatada

  @override
  void initState() {
    super.initState();
    _saldoStream = PontosService.saldoStream();
  }

  Future<void> _resgatar(Recompensa r) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Resgatar "${r.titulo}"?'),
        content: Text('Serão debitados ${r.custo} pontos do seu saldo.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Resgatar'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    setState(() => _resgatando = r.id);
    try {
      final resgate = await PontosService.resgatar(r);
      if (mounted) _mostrarVoucher(resgate);
    } on ResgateException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.mensagem)));
      }
    } finally {
      if (mounted) setState(() => _resgatando = null);
    }
  }

  void _mostrarVoucher(Resgate resgate) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.tagFound, size: 48),
        title: const Text('Resgate realizado!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(resgate.titulo, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            _CodigoVoucher(resgate.codigo),
            const SizedBox(height: 16),
            const Text(
              'Demonstração: o código fica salvo em "Meus resgates". '
              'As parcerias são exemplos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ótimo')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _saldoStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Não foi possível carregar seus pontos.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      setState(() => _saldoStream = PontosService.saldoStream()),
                  child: const Text('Tentar de novo'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final saldo = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _cartaoSaldo(saldo),
            const SizedBox(height: 16),
            _cartaoNivel(saldo),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const HistoricoPontosScreen())),
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('Histórico'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MeusResgatesScreen())),
                    icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                    label: const Text('Meus resgates'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _comoGanhar(),
            const SizedBox(height: 24),
            const Text('Recompensas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
              'Parcerias de exemplo com o comércio pet local (expansão futura do projeto).',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            for (final r in catalogoRecompensas) _itemRecompensa(r, saldo),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _cartaoSaldo(int saldo) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SEUS PONTOS',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$saldo',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2)),
              const SizedBox(width: 8),
              const Text('pts',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cartaoNivel(int saldo) {
    final nivel = PontosService.nivel(saldo);
    final proximo = nivel.proximo;
    final progresso = proximo == null
        ? 1.0
        : ((saldo - nivel.minimo) / (proximo - nivel.minimo)).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nivel.nome,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 8,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            proximo == null
                ? 'Você chegou ao nível máximo. Obrigado por ajudar!'
                : 'Faltam ${proximo - saldo} pts para o próximo nível.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _comoGanhar() {
    Widget linha(IconData icone, String texto, int pts) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icone, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(texto, style: const TextStyle(fontSize: 13))),
              Text('+$pts',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.tagFound)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Como ganhar pontos',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          linha(Icons.home_outlined, 'Publicar que acolheu um pet ("Achei")',
              AppConstants.pontosAchei),
          linha(Icons.visibility_outlined, 'Publicar que viu um pet solto ("Avistei")',
              AppConstants.pontosAvistei),
          linha(Icons.where_to_vote_outlined,
              'Registrar "Eu vi este pet" (uma vez por post)', AppConstants.pontosEuVi),
        ],
      ),
    );
  }

  Widget _itemRecompensa(Recompensa r, int saldo) {
    final pode = saldo >= r.custo;
    final carregando = _resgatando == r.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: pode ? AppColors.primaryLight : AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: r.cor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(r.icone, color: r.cor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(Recompensa.parceiroExemplo,
                    style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                Text(r.titulo,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                Text(r.descricao,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('${r.custo} pts',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: ElevatedButton(
              onPressed: pode && _resgatando == null ? () => _resgatar(r) : null,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
              child: carregando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Resgatar', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Código do voucher em destaque.
class _CodigoVoucher extends StatelessWidget {
  final String codigo;
  const _CodigoVoucher(this.codigo);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Text('CÓDIGO DO VOUCHER',
              style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          SelectableText(codigo,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: 1)),
        ],
      ),
    );
  }
}

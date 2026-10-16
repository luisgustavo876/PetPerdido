import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../models/sugestao_ia.dart';
import '../../../services/ai_service.dart';

/// Botão "Preencher com IA": chama a IA, mostra carregamento e o resultado
/// (sucesso ou erro em português), com um aviso de privacidade embaixo.
class BotaoIA extends StatefulWidget {
  final String rotulo;
  final String avisoPrivacidade;
  final String mensagemSucesso;
  final Future<SugestaoIA> Function() analisar;
  final ValueChanged<SugestaoIA> aoSugerir;

  const BotaoIA({
    super.key,
    required this.rotulo,
    required this.avisoPrivacidade,
    required this.mensagemSucesso,
    required this.analisar,
    required this.aoSugerir,
  });

  @override
  State<BotaoIA> createState() => _BotaoIAState();
}

class _BotaoIAState extends State<BotaoIA> {
  bool _analisando = false;
  String? _mensagem;
  bool _deuCerto = false;

  Future<void> _executar() async {
    setState(() {
      _analisando = true;
      _mensagem = null;
    });
    try {
      final sugestao = await widget.analisar();
      if (!mounted) return;
      widget.aoSugerir(sugestao);
      setState(() {
        _deuCerto = true;
        _mensagem = widget.mensagemSucesso;
      });
    } on IAException catch (e) {
      if (mounted) {
        setState(() {
          _deuCerto = false;
          _mensagem = e.mensagem;
        });
      }
    } finally {
      if (mounted) setState(() => _analisando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _analisando ? null : _executar,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF7C3AED),
            side: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
          ),
          icon: _analisando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome, size: 18),
          label: Text(_analisando ? 'Analisando...' : widget.rotulo),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_outlined,
                size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.avisoPrivacidade,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
        if (_mensagem != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _deuCerto
                  ? AppColors.tagFoundSurface
                  : AppColors.tagSightedSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  _deuCerto ? Icons.check_circle_outline : Icons.info_outline,
                  size: 18,
                  color: _deuCerto ? AppColors.tagFound : AppColors.tagSighted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _mensagem!,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Selo "Sugerido pela IA" ao lado do título de um campo.
class SeloIA extends StatelessWidget {
  const SeloIA({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: Color(0xFF7C3AED)),
          SizedBox(width: 4),
          Text(
            'Sugerido pela IA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }
}

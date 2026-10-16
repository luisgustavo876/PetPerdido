import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../core/post_type_style.dart';
import '../../../models/post_model.dart';
import '../post_draft.dart';
import 'post_form_ui.dart';

/// Etapa 1 — Tipo do post (Perdi / Avistei / Achei).
class StepTipo extends StatelessWidget {
  final PostDraft draft;
  final VoidCallback onChanged;

  const StepTipo({super.key, required this.draft, required this.onChanged});

  static const _opcoes = [
    (
      tipo: PostType.lost,
      titulo: 'SOS: Perdi meu pet',
      descricao: 'Seu animal de estimação fugiu ou desapareceu de casa.',
      icone: Icons.report_problem_outlined,
    ),
    (
      tipo: PostType.sighted,
      titulo: 'Avistei um pet solto',
      descricao:
          'Você viu um pet que parece estar perdido, mas não conseguiu acolhê-lo.',
      icone: Icons.visibility_outlined,
    ),
    (
      tipo: PostType.found,
      titulo: 'Estou com um pet sem dono',
      descricao: 'Você resgatou ou acolheu temporariamente um pet perdido.',
      icone: Icons.home_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepTitulo(
          titulo: 'Qual o motivo da postagem?',
          subtitulo: 'Escolha uma opção. As próximas etapas se ajustam a ela.',
        ),
        for (final opcao in _opcoes) ...[
          _cartao(opcao.tipo, opcao.titulo, opcao.descricao, opcao.icone),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _cartao(PostType tipo, String titulo, String descricao, IconData icone) {
    final selecionado = draft.type == tipo;
    final cor = tipo.color;
    return OpcaoCartao(
      selecionado: selecionado,
      cor: cor,
      onTap: () {
        draft.type = tipo;
        onChanged();
      },
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selecionado ? cor.withValues(alpha: 0.12) : AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(icone,
                color: selecionado ? cor : AppColors.textSecondary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: selecionado ? cor : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descricao,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: selecionado ? 1 : 0,
            child: Icon(Icons.check_circle, color: cor, size: 22),
          ),
        ],
      ),
    );
  }
}

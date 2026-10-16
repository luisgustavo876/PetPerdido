import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../core/formatters.dart';
import '../../../core/geo.dart';
import '../../../core/pet_options.dart';
import '../../../core/post_type_style.dart';
import '../../../core/similaridade.dart';
import '../../../models/post_model.dart';
import '../../../services/post_service.dart';
import '../../../widgets/pet_image.dart';
import '../../../widgets/pet_post_card.dart';
import '../../feed/detail_screen.dart';
import '../post_draft.dart';
import 'post_form_ui.dart';

/// Etapa 5 — Revisão: prévia do card como vai aparecer no feed, possíveis
/// correspondências (posts semelhantes) e um resumo com botões "Editar".
class StepRevisao extends StatefulWidget {
  final PostDraft draft;
  final String userName;
  final ValueChanged<int> onEditar;

  const StepRevisao({
    super.key,
    required this.draft,
    required this.userName,
    required this.onEditar,
  });

  @override
  State<StepRevisao> createState() => _StepRevisaoState();
}

class _StepRevisaoState extends State<StepRevisao> {
  /// Busca única dos posts recentes para comparar com o rascunho.
  late Future<List<PostModel>> _recentes;

  @override
  void initState() {
    super.initState();
    _recentes = PostService.postsRecentes();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final previa = d.toPostModel(
      id: 'previa',
      userId: '',
      userName: widget.userName,
      agora: DateTime.now(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepTitulo(
          titulo: 'Confira antes de publicar',
          subtitulo: 'É assim que o anúncio vai aparecer no feed.',
        ),
        // Prévia não clicável.
        IgnorePointer(
          child: PetPostCard(post: previa, fotoLocal: d.imageBytes),
        ),
        const SizedBox(height: 16),
        _correspondencias(previa),
        const SizedBox(height: 16),
        _linha(etapa: 0, titulo: 'Tipo', texto: d.type.label),
        _linha(
          etapa: 1,
          titulo: 'Foto',
          texto: d.imageBytes == null ? 'Sem foto' : 'Foto adicionada',
        ),
        _linha(
          etapa: 2,
          titulo: 'Sobre o pet',
          texto: [
            if (d.type == PostType.lost) previa.petName,
            previa.species,
            previa.breed,
            previa.size,
            previa.sex,
            if (previa.colors.isNotEmpty) previa.colors.join(' e '),
          ].join(' · '),
          detalhe: previa.description,
        ),
        _linha(
          etapa: 3,
          titulo: 'Onde e quando',
          texto: previa.lastSeenAddress,
          detalhe: formatarDataHora(previa.eventAt),
        ),
      ],
    );
  }

  /// "Possíveis correspondências": posts de tipo oposto parecidos com este.
  Widget _correspondencias(PostModel previa) {
    return FutureBuilder<List<PostModel>>(
      future: _recentes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _CaixaInfo(
            icone: Icons.manage_search,
            texto: 'Procurando posts parecidos...',
            carregando: true,
          );
        }
        if (snapshot.hasError) {
          return _CaixaInfo(
            icone: Icons.cloud_off,
            texto: 'Não foi possível procurar posts parecidos.',
            acao: TextButton(
              onPressed: () =>
                  setState(() => _recentes = PostService.postsRecentes()),
              child: const Text('Tentar de novo'),
            ),
          );
        }
        final achados =
            Similaridade.correspondencias(previa, snapshot.data ?? const []);
        if (achados.isEmpty) {
          return const _CaixaInfo(
            icone: Icons.check_circle_outline,
            texto: 'Nenhum post parecido por perto nos últimos dias.',
          );
        }
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.tagSightedSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.tagSighted.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.tagSighted, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Possíveis correspondências',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Confira se algum destes é o mesmo pet antes de publicar.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              for (final post in achados) _itemCorrespondencia(previa, post),
            ],
          ),
        );
      },
    );
  }

  Widget _itemCorrespondencia(PostModel previa, PostModel post) {
    final km = Geo.distanciaKm(
        previa.latitude, previa.longitude, post.latitude, post.longitude);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(post: post)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: ColoredBox(
                  color: AppColors.background,
                  child: PetImage(url: post.photoUrl, iconSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.type.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: post.type.color,
                    ),
                  ),
                  Text(
                    [post.species, post.size, ...post.colors].join(' · '),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${post.lastSeenAddress} · ${Formatters.distancia(km)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _linha({
    required int etapa,
    required String titulo,
    required String texto,
    String? detalhe,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                if (detalhe != null && detalhe.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    detalhe,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () => widget.onEditar(etapa),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }
}

/// Caixa simples de informação (carregando, nada encontrado, erro).
class _CaixaInfo extends StatelessWidget {
  final IconData icone;
  final String texto;
  final bool carregando;
  final Widget? acao;

  const _CaixaInfo({
    required this.icone,
    required this.texto,
    this.carregando = false,
    this.acao,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          carregando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icone, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          if (acao != null) acao!,
        ],
      ),
    );
  }
}

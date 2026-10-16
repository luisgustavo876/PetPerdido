import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../models/post_model.dart';
import '../../../widgets/pet_post_card.dart';
import '../post_draft.dart';
import '../../../core/pet_options.dart';
import 'post_form_ui.dart';

/// Etapa 5 — Revisão: prévia do card como vai aparecer no feed e um resumo
/// com botões "Editar" que voltam para a etapa correspondente.
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
  /// Entrega a foto escolhida (que ainda não foi enviada ao Storage) ao
  /// PetPostCard: ele carrega imagens que não são URL como asset, e aqui o
  /// "asset" [_FotoLocalBundle.chave] é a própria foto em memória.
  _FotoLocalBundle? _bundle;

  @override
  void initState() {
    super.initState();
    final bytes = widget.draft.imageBytes;
    if (bytes != null) _bundle = _FotoLocalBundle(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final agora = DateTime.now();
    final previa = d.toPostModel(
      id: 'previa',
      userId: '',
      userName: widget.userName,
      agora: agora,
      photoUrl: _bundle == null ? null : _FotoLocalBundle.chave,
    );

    Widget card = PetPostCard(post: previa);
    if (_bundle != null) {
      card = DefaultAssetBundle(bundle: _bundle!, child: card);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepTitulo(
          titulo: 'Confira antes de publicar',
          subtitulo: 'É assim que o anúncio vai aparecer no feed.',
        ),
        // Prévia não clicável (o botão "Conversar" do card não faz sentido aqui).
        IgnorePointer(child: card),
        const SizedBox(height: 24),
        _linha(
          etapa: 0,
          titulo: 'Tipo',
          texto: d.type.label,
        ),
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

/// AssetBundle que responde a [chave] com os bytes da foto escolhida e
/// repassa todo o resto ao bundle normal do app.
class _FotoLocalBundle extends CachingAssetBundle {
  static const chave = 'previa/foto-local';
  final Uint8List bytes;

  _FotoLocalBundle(this.bytes);

  @override
  Future<ByteData> load(String key) {
    if (key == chave) return Future.value(ByteData.sublistView(bytes));
    return rootBundle.load(key);
  }

  @override
  Future<ui.ImmutableBuffer> loadBuffer(String key) {
    if (key == chave) return ui.ImmutableBuffer.fromUint8List(bytes);
    return rootBundle.loadBuffer(key);
  }
}

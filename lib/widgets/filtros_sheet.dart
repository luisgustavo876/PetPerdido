import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/pet_options.dart';
import '../models/post_filter.dart';
import '../models/post_model.dart';

/// Painel (bottom sheet) de filtros, usado pelo Mapa e pelo Feed.
/// Cada tela escolhe quais seções aparecem.
class FiltrosSheet extends StatefulWidget {
  final PostFilter inicial;
  final bool mostrarPorte;
  final bool mostrarCor;
  final bool mostrarPeriodo;
  final bool mostrarResolvidos;
  final bool mostrarOrdem;

  const FiltrosSheet({
    super.key,
    required this.inicial,
    this.mostrarPorte = false,
    this.mostrarCor = false,
    this.mostrarPeriodo = false,
    this.mostrarResolvidos = false,
    this.mostrarOrdem = false,
  });

  /// Abre o painel e devolve os filtros escolhidos (ou null se fechar).
  static Future<PostFilter?> abrir(
    BuildContext context, {
    required PostFilter inicial,
    bool mostrarPorte = false,
    bool mostrarCor = false,
    bool mostrarPeriodo = false,
    bool mostrarResolvidos = false,
    bool mostrarOrdem = false,
  }) {
    return showModalBottomSheet<PostFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => FiltrosSheet(
        inicial: inicial,
        mostrarPorte: mostrarPorte,
        mostrarCor: mostrarCor,
        mostrarPeriodo: mostrarPeriodo,
        mostrarResolvidos: mostrarResolvidos,
        mostrarOrdem: mostrarOrdem,
      ),
    );
  }

  @override
  State<FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<FiltrosSheet> {
  late PostFilter _f = widget.inicial;

  static const _tipos = [
    (PostType.lost, 'Perdidos'),
    (PostType.found, 'Achados'),
    (PostType.sighted, 'Avistados'),
  ];

  void _alterar(PostFilter novo) => setState(() => _f = novo);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filtros',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        _alterar(PostFilter(ordem: _f.ordem)), // limpa filtros
                    child: const Text('Limpar'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _secoes(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _f),
                child: const Text('Aplicar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _secoes() {
    return [
      if (widget.mostrarOrdem)
        _secao('Ordenar por', [
          for (final o in OrdemFeed.values)
            _chip(o.rotulo, _f.ordem == o, () => _alterar(_f.copyWith(ordem: o))),
        ]),
      _secao('Tipo', [
        for (final (tipo, rotulo) in _tipos)
          _chip(rotulo, _f.tipos.contains(tipo), () {
            final tipos = {..._f.tipos};
            tipos.contains(tipo) ? tipos.remove(tipo) : tipos.add(tipo);
            _alterar(_f.copyWith(tipos: tipos));
          }),
      ]),
      _secao('Espécie', [
        _chip('Todas', _f.especie == null,
            () => _alterar(_f.copyWith(especie: null))),
        for (final especie in PetOptions.especies.keys)
          _chip(especie, _f.especie == especie,
              () => _alterar(_f.copyWith(especie: especie))),
      ]),
      if (widget.mostrarPorte)
        _secao('Porte', [
          _chip('Todos', _f.porte == null, () => _alterar(_f.copyWith(porte: null))),
          for (final porte in PetOptions.portes.keys)
            _chip(porte, _f.porte == porte,
                () => _alterar(_f.copyWith(porte: porte))),
        ]),
      if (widget.mostrarCor)
        _secao('Cor', [
          _chip('Todas', _f.cor == null, () => _alterar(_f.copyWith(cor: null))),
          for (final cor in PetOptions.cores.keys)
            _chip(cor, _f.cor == cor, () => _alterar(_f.copyWith(cor: cor))),
        ]),
      if (widget.mostrarPeriodo)
        _secao('Período', [
          for (final p in PeriodoFiltro.values)
            _chip(p.rotulo, _f.periodo == p,
                () => _alterar(_f.copyWith(periodo: p))),
        ]),
      if (widget.mostrarResolvidos)
        _interruptor('Incluir resolvidos', _f.incluirResolvidos,
            (v) => _alterar(_f.copyWith(incluirResolvidos: v))),
    ];
  }

  Widget _secao(String titulo, List<Widget> chips) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }

  Widget _chip(String rotulo, bool selecionado, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(rotulo),
      selected: selecionado,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selecionado ? Colors.white : AppColors.onSurface,
      ),
    );
  }

  Widget _interruptor(String titulo, bool valor, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(titulo,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        value: valor,
        activeThumbColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }
}

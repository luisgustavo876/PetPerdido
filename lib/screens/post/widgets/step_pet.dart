import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../core/pet_options.dart';
import '../../../models/post_model.dart';
import '../../../services/ai_service.dart';
import '../post_draft.dart';
import 'botao_ia.dart';
import 'post_form_ui.dart';

/// Etapa 3 — Sobre o pet: nome (só Perdi), espécie, cor, raça, porte, sexo,
/// características e descrição.
class StepPet extends StatelessWidget {
  final PostDraft draft;
  final VoidCallback onChanged;

  const StepPet({super.key, required this.draft, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepTitulo(
          titulo: draft.type == PostType.lost ? 'Sobre o seu pet' : 'Sobre o pet',
          subtitulo: 'Quanto mais detalhes, mais fácil reconhecer.',
        ),
        if (draft.type == PostType.lost) ...[
          const RotuloSecao('Nome do pet'),
          TextField(
            controller: draft.petNameController,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(hintText: 'Ex.: Pipoca, Max, Lola'),
          ),
          const SizedBox(height: 24),
        ],
        RotuloSecao('Espécie', complemento: _selo('especie')),
        _especies(),
        const SizedBox(height: 24),
        RotuloSecao(
          'Cor',
          complemento: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selo('cores') != null) ...[
                _selo('cores')!,
                const SizedBox(width: 8),
              ],
              Text(
                'até ${PetOptions.maxCores} · ${draft.colors.length} escolhida(s)',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        _cores(),
        const SizedBox(height: 24),
        RotuloSecao('Raça', complemento: _selo('raca')),
        _raca(),
        const SizedBox(height: 24),
        RotuloSecao('Porte', complemento: _selo('porte')),
        _portes(),
        const SizedBox(height: 24),
        const RotuloSecao('Sexo'),
        _sexos(),
        const SizedBox(height: 24),
        RotuloSecao('Características', complemento: _selo('caracteristicas')),
        _caracteristicas(context),
        const SizedBox(height: 24),
        const RotuloSecao('Descrição'),
        _descricao(),
        // Avistei sem foto: a IA preenche a partir do texto digitado.
        if (draft.type == PostType.sighted && draft.imageBytes == null) ...[
          const SizedBox(height: 16),
          BotaoIA(
            rotulo: 'Preencher a partir da descrição',
            avisoPrivacidade:
                'A descrição é enviada à IA do Google (Gemini) só para '
                'identificar espécie, porte, cor e raça.',
            mensagemSucesso: 'Pronto! Confira os campos marcados acima.',
            analisar: () {
              final texto = draft.descriptionController.text.trim();
              if (texto.length < 10) {
                throw const IAException(
                    'Escreva a descrição primeiro (mínimo de 10 caracteres).');
              }
              return AIService.analisarDescricao(texto);
            },
            aoSugerir: (sugestao) {
              draft.aplicarSugestao(sugestao);
              onChanged();
            },
          ),
        ],
      ],
    );
  }

  /// Selo "Sugerido pela IA" se o campo veio da IA e ainda não foi mexido.
  Widget? _selo(String campo) =>
      draft.sugeridosPelaIA.contains(campo) ? const SeloIA() : null;

  /// O usuário mexeu no campo: ele deixa de ser "sugerido pela IA".
  void _editou(String campo) {
    draft.sugeridosPelaIA.remove(campo);
    onChanged();
  }

  Widget _especies() {
    return Row(
      children: [
        for (final (i, MapEntry(key: especie, value: emoji))
            in PetOptions.especies.entries.indexed) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(
            child: OpcaoCartao(
              selecionado: draft.species == especie,
              padding: const EdgeInsets.symmetric(vertical: 24),
              onTap: () {
                if (draft.species == especie) return;
                draft.species = especie;
                draft.breed = PetOptions.racaPadrao; // raças mudam por espécie
                draft.sugeridosPelaIA.remove('raca');
                _editou('especie');
              },
              child: Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(
                    especie,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: draft.species == especie
                          ? AppColors.primary
                          : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _cores() {
    final cheio = draft.colors.length >= PetOptions.maxCores;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final MapEntry(key: nome, value: tons) in PetOptions.cores.entries)
          FilterChip(
            avatar: _BolinhaCor(tons),
            label: Text(nome),
            selected: draft.colors.contains(nome),
            showCheckmark: false,
            selectedColor: AppColors.primarySurface,
            side: BorderSide(
              color: draft.colors.contains(nome)
                  ? AppColors.primary
                  : AppColors.divider,
            ),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: draft.colors.contains(nome)
                  ? AppColors.primary
                  : AppColors.onSurface,
            ),
            // Com 2 escolhidas, as outras ficam desabilitadas.
            onSelected: !draft.colors.contains(nome) && cheio
                ? null
                : (marcado) {
                    marcado ? draft.colors.add(nome) : draft.colors.remove(nome);
                    _editou('cores');
                  },
          ),
      ],
    );
  }

  Widget _raca() {
    final racas = PetOptions.racas[draft.species] ?? const [PetOptions.racaPadrao];
    return Autocomplete<String>(
      // Recria o campo quando a espécie muda (a raça volta ao padrão) ou
      // quando a IA sugere uma raça nova.
      key: ValueKey('${draft.species}-${draft.versaoIA}'),
      initialValue: TextEditingValue(text: draft.breed),
      optionsBuilder: (valor) {
        final busca = valor.text.trim().toLowerCase();
        if (busca.isEmpty || busca == PetOptions.racaPadrao.toLowerCase()) {
          return racas;
        }
        return racas.where((r) => r.toLowerCase().contains(busca));
      },
      onSelected: (raca) {
        draft.breed = raca;
        _editou('raca');
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          onChanged: (texto) {
            draft.breed = texto;
            _editou('raca');
          },
          decoration: const InputDecoration(
            hintText: 'Comece a digitar para ver sugestões',
            suffixIcon: Icon(Icons.arrow_drop_down),
          ),
        );
      },
    );
  }

  Widget _portes() {
    return Row(
      children: [
        for (final (i, MapEntry(key: porte, value: peso))
            in PetOptions.portes.entries.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: OpcaoCartao(
              selecionado: draft.size == porte,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              onTap: () {
                draft.size = porte;
                _editou('porte');
              },
              child: Column(
                children: [
                  Text(
                    porte,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: draft.size == porte
                          ? AppColors.primary
                          : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    peso,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sexos() {
    return Row(
      children: [
        for (final (i, sexo) in PetOptions.sexos.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: OpcaoCartao(
              selecionado: draft.sex == sexo,
              padding: const EdgeInsets.symmetric(vertical: 16),
              onTap: () {
                draft.sex = sexo;
                onChanged();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    sexo == 'Macho' ? Icons.male : Icons.female,
                    size: 18,
                    color: draft.sex == sexo
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sexo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: draft.sex == sexo
                          ? AppColors.primary
                          : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Características pré-definidas por grupo e, no fim, as próprias do
  /// usuário (selecionadas e removíveis) com o chip "+ Adicionar".
  Widget _caracteristicas(BuildContext context) {
    final proprias = draft.caracteristicasProprias;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final MapEntry(key: grupo, value: itens)
            in PetOptions.gruposCaracteristicas.entries) ...[
          Text(grupo,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final item in itens) _chipCaracteristica(item)],
          ),
          const SizedBox(height: 16),
        ],
        const Text('Outras',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in proprias)
              InputChip(
                label: Text(item),
                selected: true,
                showCheckmark: false,
                selectedColor: AppColors.primarySurface,
                side: const BorderSide(color: AppColors.primary),
                labelStyle:
                    const TextStyle(fontSize: 12, color: AppColors.primary),
                deleteIcon: const Icon(Icons.close, size: 16),
                deleteIconColor: AppColors.primary,
                deleteButtonTooltipMessage: 'Remover',
                onDeleted: () {
                  draft.traits.remove(item);
                  _editou('caracteristicas');
                },
              ),
            if (proprias.length < PetOptions.maxCaracteristicasProprias)
              ActionChip(
                avatar: const Icon(Icons.add, size: 16, color: AppColors.primary),
                label: const Text('Adicionar'),
                labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
                side: const BorderSide(color: AppColors.divider),
                onPressed: () => _adicionarCaracteristica(context),
              ),
          ],
        ),
      ],
    );
  }

  Widget _chipCaracteristica(String item) {
    final marcado = draft.traits.contains(item);
    return FilterChip(
      label: Text(item),
      selected: marcado,
      showCheckmark: false,
      selectedColor: AppColors.primarySurface,
      side: BorderSide(color: marcado ? AppColors.primary : AppColors.divider),
      labelStyle: TextStyle(
        fontSize: 12,
        color: marcado ? AppColors.primary : AppColors.onSurface,
      ),
      onSelected: (sim) {
        sim ? draft.traits.add(item) : draft.traits.remove(item);
        _editou('caracteristicas');
      },
    );
  }

  /// Caixa para digitar uma característica própria (2 a 24 caracteres, sem
  /// repetir e sem palavrões). Fica aberta mostrando o erro até dar certo.
  Future<void> _adicionarCaracteristica(BuildContext context) async {
    final controller = TextEditingController();
    String? erro;
    final adicionou = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialogo) {
          void salvar() {
            final msg = draft.adicionarCaracteristica(controller.text);
            if (msg == null) {
              Navigator.pop(ctx, true);
            } else {
              setStateDialogo(() => erro = msg);
            }
          }

          return AlertDialog(
            title: const Text('Nova característica'),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLength: PetOptions.maxTamanhoCaracteristica,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (erro != null) setStateDialogo(() => erro = null);
              },
              onSubmitted: (_) => salvar(),
              decoration: InputDecoration(
                hintText: 'Ex.: Mancha branca no peito',
                errorText: erro,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(onPressed: salvar, child: const Text('Adicionar')),
            ],
          );
        },
      ),
    );
    controller.dispose();
    if (adicionou == true) _editou('caracteristicas');
  }

  Widget _descricao() {
    final tamanho = draft.descriptionController.text.trim().length;
    final ok = tamanho >= 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: draft.descriptionController,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            hintText: 'Manchas, coleira, marcas, como ele reage a estranhos...',
          ),
        ),
        const SizedBox(height: 8),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ok ? AppColors.tagFound : AppColors.textTertiary,
          ),
          child: Text('$tamanho/10 mínimo'),
        ),
      ],
    );
  }
}

/// Bolinha com a cor do pet (dividida quando há mais de um tom).
class _BolinhaCor extends StatelessWidget {
  final List<Color> tons;

  const _BolinhaCor(this.tons);

  @override
  Widget build(BuildContext context) {
    // Faixas com divisão "seca" entre as cores.
    final stops = <double>[];
    final cores = <Color>[];
    for (var i = 0; i < tons.length; i++) {
      stops
        ..add(i / tons.length)
        ..add((i + 1) / tons.length);
      cores
        ..add(tons[i])
        ..add(tons[i]);
    }
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: cores, stops: stops),
        border: Border.all(color: AppColors.divider),
      ),
    );
  }
}

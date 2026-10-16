import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';

/// Peças visuais compartilhadas pelas etapas do formulário de post.
/// Espaçamentos em múltiplos de 8 e cantos de 16.

/// Título e subtítulo no topo de cada etapa.
class StepTitulo extends StatelessWidget {
  final String titulo;
  final String? subtitulo;

  const StepTitulo({super.key, required this.titulo, this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.4,
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitulo!,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Rótulo de uma seção dentro da etapa, com um complemento opcional à direita.
class RotuloSecao extends StatelessWidget {
  final String texto;
  final Widget? complemento;

  const RotuloSecao(this.texto, {super.key, this.complemento});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ),
          if (complemento != null) complemento!,
        ],
      ),
    );
  }
}

/// Etiqueta pequena "Obrigatória" / "Opcional".
class EtiquetaObrigatoria extends StatelessWidget {
  final bool obrigatoria;

  const EtiquetaObrigatoria({super.key, required this.obrigatoria});

  @override
  Widget build(BuildContext context) {
    final cor = obrigatoria ? AppColors.primary : AppColors.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: obrigatoria ? AppColors.primarySurface : AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        obrigatoria ? 'Obrigatória' : 'Opcional',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cor),
      ),
    );
  }
}

/// Cartão selecionável com animação de seleção.
class OpcaoCartao extends StatelessWidget {
  final bool selecionado;
  final VoidCallback onTap;
  final Widget child;
  final Color cor;
  final EdgeInsetsGeometry padding;

  const OpcaoCartao({
    super.key,
    required this.selecionado,
    required this.onTap,
    required this.child,
    this.cor = AppColors.primary,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: padding,
        decoration: BoxDecoration(
          color: selecionado ? cor.withValues(alpha: 0.06) : AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selecionado ? cor : AppColors.divider,
            width: selecionado ? 2 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Indicador das etapas com rótulos (Tipo · Foto · Pet · Local · Revisar).
/// Etapas já concluídas podem ser tocadas para voltar.
class IndicadorEtapas extends StatelessWidget {
  final List<String> rotulos;
  final int atual;
  final ValueChanged<int> onVoltarPara;

  const IndicadorEtapas({
    super.key,
    required this.rotulos,
    required this.atual,
    required this.onVoltarPara,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          for (var i = 0; i < rotulos.length; i++) ...[
            if (i > 0)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  color: i <= atual ? AppColors.primary : AppColors.divider,
                ),
              ),
            _bolinha(i),
          ],
        ],
      ),
    );
  }

  Widget _bolinha(int i) {
    final feita = i < atual;
    final ativa = i == atual;
    return GestureDetector(
      onTap: feita ? () => onVoltarPara(i) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: feita || ativa ? AppColors.primary : AppColors.surface,
              border: Border.all(
                color: feita || ativa ? AppColors.primary : AppColors.divider,
                width: 2,
              ),
            ),
            child: feita
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ativa ? Colors.white : AppColors.textTertiary,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            rotulos[i],
            style: TextStyle(
              fontSize: 11,
              fontWeight: ativa ? FontWeight.w700 : FontWeight.w500,
              color: ativa || feita ? AppColors.onSurface : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Caixa de erro dentro da tela (não só SnackBar).
class AvisoErro extends StatelessWidget {
  final String mensagem;

  const AvisoErro(this.mensagem, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensagem,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

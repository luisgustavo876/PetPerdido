import '../core/formatters.dart';
import 'post_model.dart';

/// Período do filtro, contado a partir de quando o fato aconteceu (eventAt).
enum PeriodoFiltro {
  tudo('Qualquer data', null),
  h24('Últimas 24 h', Duration(hours: 24)),
  d7('Últimos 7 dias', Duration(days: 7)),
  d30('Últimos 30 dias', Duration(days: 30));

  final String rotulo;
  final Duration? janela;
  const PeriodoFiltro(this.rotulo, this.janela);
}

/// Ordem da lista do feed.
enum OrdemFeed {
  recentes('Mais recentes'),
  maisPerto('Mais perto de mim');

  final String rotulo;
  const OrdemFeed(this.rotulo);
}

/// Filtros do mapa e do feed. Imutável: use [copyWith] para alterar.
/// Campos nulos ou vazios significam "qualquer um".
class PostFilter {
  final Set<PostType> tipos;
  final String? especie;
  final String? porte;
  final String? cor;
  final PeriodoFiltro periodo;
  final bool incluirResolvidos;
  final OrdemFeed ordem;

  const PostFilter({
    this.tipos = const {},
    this.especie,
    this.porte,
    this.cor,
    this.periodo = PeriodoFiltro.tudo,
    this.incluirResolvidos = false,
    this.ordem = OrdemFeed.recentes,
  });

  static const _mantem = Object();

  /// Para limpar um campo opcional, passe null (ex.: `copyWith(cor: null)`).
  PostFilter copyWith({
    Set<PostType>? tipos,
    Object? especie = _mantem,
    Object? porte = _mantem,
    Object? cor = _mantem,
    PeriodoFiltro? periodo,
    bool? incluirResolvidos,
    OrdemFeed? ordem,
  }) {
    return PostFilter(
      tipos: tipos ?? this.tipos,
      especie: identical(especie, _mantem) ? this.especie : especie as String?,
      porte: identical(porte, _mantem) ? this.porte : porte as String?,
      cor: identical(cor, _mantem) ? this.cor : cor as String?,
      periodo: periodo ?? this.periodo,
      incluirResolvidos: incluirResolvidos ?? this.incluirResolvidos,
      ordem: ordem ?? this.ordem,
    );
  }

  /// Quantos filtros estão ativos (para o contador do botão). A ordem não conta.
  int get quantidadeAtivos => [
        tipos.isNotEmpty,
        especie != null,
        porte != null,
        cor != null,
        periodo != PeriodoFiltro.tudo,
        incluirResolvidos,
      ].where((ativo) => ativo).length;

  /// O post passa nos filtros? Função pura.
  bool aceita(PostModel post, {required DateTime agora}) {
    if (!incluirResolvidos && post.isResolved) return false;
    if (tipos.isNotEmpty && !tipos.contains(post.type)) return false;
    if (especie != null && post.species != especie) return false;
    if (porte != null && post.size != porte) return false;
    if (cor != null && !post.colors.contains(cor)) return false;
    final janela = periodo.janela;
    if (janela != null && agora.difference(post.eventAt) > janela) return false;
    return true;
  }

  /// Busca por texto em nome, raça, descrição, bairro, cor, tags, espécie e
  /// características — sem diferenciar maiúsculas nem acentos.
  /// Todas as palavras digitadas precisam aparecer. Função pura.
  static bool buscaCorresponde(PostModel post, String busca) {
    final palavras = Formatters.normalizar(busca)
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty);
    if (palavras.isEmpty) return true;
    final texto = Formatters.normalizar([
      post.petName,
      post.breed,
      post.description,
      post.lastSeenAddress,
      post.species,
      ...post.colors,
      ...post.tags,
      ...post.traits,
    ].join(' '));
    return palavras.every(texto.contains);
  }
}

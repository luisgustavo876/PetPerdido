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
  final bool soFavoritos;
  final OrdemFeed ordem;

  const PostFilter({
    this.tipos = const {},
    this.especie,
    this.porte,
    this.cor,
    this.periodo = PeriodoFiltro.tudo,
    this.incluirResolvidos = false,
    this.soFavoritos = false,
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
    bool? soFavoritos,
    OrdemFeed? ordem,
  }) {
    return PostFilter(
      tipos: tipos ?? this.tipos,
      especie: identical(especie, _mantem) ? this.especie : especie as String?,
      porte: identical(porte, _mantem) ? this.porte : porte as String?,
      cor: identical(cor, _mantem) ? this.cor : cor as String?,
      periodo: periodo ?? this.periodo,
      incluirResolvidos: incluirResolvidos ?? this.incluirResolvidos,
      soFavoritos: soFavoritos ?? this.soFavoritos,
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
        soFavoritos,
      ].where((ativo) => ativo).length;

  /// O post passa nos filtros? Função pura.
  bool aceita(PostModel post,
      {required DateTime agora, Set<String> favoritos = const {}}) {
    if (!incluirResolvidos && post.isResolved) return false;
    if (tipos.isNotEmpty && !tipos.contains(post.type)) return false;
    if (especie != null && post.species != especie) return false;
    if (porte != null && post.size != porte) return false;
    if (cor != null && !post.colors.contains(cor)) return false;
    if (soFavoritos && !favoritos.contains(post.id)) return false;
    final janela = periodo.janela;
    if (janela != null && agora.difference(post.eventAt) > janela) return false;
    return true;
  }
}

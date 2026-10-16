import 'dart:convert';
import '../core/pet_options.dart';

/// Sugestões da IA para a etapa "Sobre o pet". Só contém valores que existem
/// no app (espécie, porte, cores e características das listas de [PetOptions]).
class SugestaoIA {
  /// "Cão", "Gato" ou null se a IA não identificou um cão ou gato.
  final String? especie;
  final String? porte;
  final List<String> cores;
  final String raca;
  final List<String> caracteristicas;

  const SugestaoIA({
    this.especie,
    this.porte,
    this.cores = const [],
    this.raca = PetOptions.racaPadrao,
    this.caracteristicas = const [],
  });

  /// A IA disse que não há cão nem gato (espécie "Indefinido").
  bool get naoEhPet => especie == null;

  static const _tamanhoMaxRaca = 40;

  /// Converte a resposta (texto JSON) do modelo nos valores permitidos do app.
  /// Ignora valores fora das listas, limita as cores a [PetOptions.maxCores]
  /// e a raça a um texto curto. Retorna null se a resposta não for um JSON
  /// de objeto válido. Função pura.
  static SugestaoIA? converter(String? resposta) {
    if (resposta == null || resposta.trim().isEmpty) return null;
    final Object? json;
    try {
      json = jsonDecode(_semCercas(resposta));
    } catch (_) {
      return null;
    }
    if (json is! Map) return null;

    String? daLista(Object? valor, Iterable<String> permitidos) {
      if (valor is! String) return null;
      for (final p in permitidos) {
        if (p.toLowerCase() == valor.trim().toLowerCase()) return p;
      }
      return null;
    }

    List<String> listaDaLista(Object? valores, Iterable<String> permitidos,
        {int? maximo}) {
      if (valores is! List) return const [];
      final saida = <String>[];
      for (final v in valores) {
        final ok = daLista(v, permitidos);
        if (ok != null && !saida.contains(ok)) saida.add(ok);
        if (maximo != null && saida.length == maximo) break;
      }
      return saida;
    }

    final especie = daLista(json['species'], PetOptions.especies.keys);
    final rawRaca = json['breed'];
    var raca = rawRaca is String ? rawRaca.trim() : '';
    if (raca.isEmpty || raca.toLowerCase() == 'indefinido') {
      raca = PetOptions.racaPadrao;
    } else if (raca.length > _tamanhoMaxRaca) {
      raca = raca.substring(0, _tamanhoMaxRaca).trim();
    }

    return SugestaoIA(
      especie: especie,
      porte: daLista(json['size'], PetOptions.portes.keys),
      cores: listaDaLista(json['colors'], PetOptions.cores.keys,
          maximo: PetOptions.maxCores),
      raca: raca,
      caracteristicas:
          listaDaLista(json['traits'], PetOptions.caracteristicas),
    );
  }

  /// Alguns modelos devolvem o JSON dentro de ```json ... ```.
  static String _semCercas(String texto) {
    final t = texto.trim();
    if (!t.startsWith('```')) return t;
    final inicio = t.indexOf('\n');
    final fim = t.lastIndexOf('```');
    if (inicio < 0 || fim <= inicio) return t;
    return t.substring(inicio + 1, fim);
  }
}

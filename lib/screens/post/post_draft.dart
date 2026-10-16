import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_constants.dart';
import '../../models/post_model.dart';
import '../../models/sugestao_ia.dart';
import '../../services/location_service.dart';
import '../../core/pet_options.dart';

/// Atalhos de "quando aconteceu" da etapa Onde e quando.
enum QuandoAconteceu { agora, hojeDeManha, ontem, escolhido }

/// Estado do formulário de criar post, compartilhado entre as 5 etapas.
///
/// É uma classe simples (sem gerenciador de estado): as etapas alteram os
/// campos e avisam a tela pai, que chama setState.
class PostDraft {
  static const totalEtapas = 5;
  static const rotulosEtapas = ['Tipo', 'Foto', 'Pet', 'Local', 'Revisar'];

  // Etapa 1 — Tipo
  PostType type = PostType.lost;

  // Etapa 2 — Foto
  XFile? imageFile;
  Uint8List? imageBytes;

  // Etapa 3 — Sobre o pet
  final petNameController = TextEditingController();
  final descriptionController = TextEditingController();
  String species = 'Cão';
  final Set<String> colors = {};
  String breed = PetOptions.racaPadrao;
  String size = 'Médio';
  String sex = 'Macho';
  final Set<String> traits = {'Sem Coleira'};

  // Etapa 4 — Onde e quando
  final addressController = TextEditingController();

  /// Posição do marcador no mapa (sem arredondar; arredonda ao publicar).
  ({double lat, double lng})? position;
  QuandoAconteceu quando = QuandoAconteceu.agora;
  DateTime? dataEscolhida; // usada quando quando == escolhido

  /// Campos preenchidos pela IA que o usuário ainda não mexeu
  /// (mostram o selo "Sugerido pela IA"): especie, porte, cores, raca,
  /// caracteristicas.
  final Set<String> sugeridosPelaIA = {};

  /// Aumenta a cada sugestão aplicada (recria o campo de raça com o valor novo).
  int versaoIA = 0;

  bool get fotoObrigatoria => type != PostType.sighted;

  /// Aplica as sugestões da IA nos campos da etapa "Sobre o pet".
  /// Tudo continua editável; ao editar, o campo perde o selo.
  void aplicarSugestao(SugestaoIA s) {
    versaoIA++;
    sugeridosPelaIA.clear();
    if (s.especie != null && PetOptions.especies.containsKey(s.especie)) {
      species = s.especie!;
      sugeridosPelaIA.add('especie');
    }
    if (s.porte != null) {
      size = s.porte!;
      sugeridosPelaIA.add('porte');
    }
    if (s.cores.isNotEmpty) {
      colors
        ..clear()
        ..addAll(s.cores.take(PetOptions.maxCores));
      sugeridosPelaIA.add('cores');
    }
    breed = s.raca;
    sugeridosPelaIA.add('raca');
    if (s.caracteristicas.isNotEmpty) {
      traits.addAll(s.caracteristicas);
      sugeridosPelaIA.add('caracteristicas');
    }
  }

  /// Título da etapa 4, conforme o tipo do post.
  String get tituloLocal => switch (type) {
        PostType.lost => 'Onde e quando sumiu?',
        PostType.found => 'Onde você encontrou?',
        PostType.sighted => 'Onde você viu?',
      };

  /// Rótulo da seção de data/hora, conforme o tipo do post.
  String get tituloQuando => switch (type) {
        PostType.lost => 'Quando sumiu?',
        PostType.found => 'Quando encontrou?',
        PostType.sighted => 'Quando viu?',
      };

  /// Data de um atalho. "Hoje de manhã" = hoje às 9h (null se ainda não
  /// chegou); "Ontem" = ontem ao meio-dia. Função pura.
  static DateTime? dataDoAtalho(QuandoAconteceu q, DateTime agora) {
    switch (q) {
      case QuandoAconteceu.agora:
        return agora;
      case QuandoAconteceu.hojeDeManha:
        final manha = DateTime(agora.year, agora.month, agora.day, 9);
        return manha.isAfter(agora) ? null : manha;
      case QuandoAconteceu.ontem:
        return DateTime(agora.year, agora.month, agora.day - 1, 12);
      case QuandoAconteceu.escolhido:
        return null;
    }
  }

  /// Quando o fato aconteceu. "Agora" é calculado na hora de publicar.
  DateTime eventAt(DateTime agora) => quando == QuandoAconteceu.escolhido
      ? (dataEscolhida ?? agora)
      : (dataDoAtalho(quando, agora) ?? agora);

  /// Validação de uma etapa (0 a 4). Retorna a mensagem de erro ou null.
  String? validarEtapa(int etapa, DateTime agora) {
    switch (etapa) {
      case 1:
        if (fotoObrigatoria && imageBytes == null) {
          return 'A foto é obrigatória para "${type.label}".';
        }
      case 2:
        if (type == PostType.lost && petNameController.text.trim().isEmpty) {
          return 'Informe o nome do pet.';
        }
        if (colors.isEmpty) return 'Escolha pelo menos uma cor.';
        if (colors.length > PetOptions.maxCores) {
          return 'Escolha no máximo ${PetOptions.maxCores} cores.';
        }
        if (descriptionController.text.trim().length < 10) {
          return 'Descreva o pet com pelo menos 10 caracteres.';
        }
      case 3:
        if (position == null) return 'Marque no mapa onde o pet foi visto.';
        final endereco = addressController.text.trim();
        if (endereco.isEmpty ||
            endereco.toLowerCase() ==
                PetOptions.enderecoGenerico.toLowerCase()) {
          return 'Informe o bairro para os outros acharem o pet';
        }
        if (eventAt(agora).isAfter(agora)) {
          return 'A data e a hora não podem ser no futuro.';
        }
    }
    return null;
  }

  /// Primeira etapa (antes da revisão) com erro, ou null se está tudo certo.
  int? primeiraEtapaInvalida(DateTime agora) {
    for (var etapa = 0; etapa < totalEtapas - 1; etapa++) {
      if (validarEtapa(etapa, agora) != null) return etapa;
    }
    return null;
  }

  /// Monta o post a partir do formulário (usado na prévia e ao publicar).
  /// As coordenadas do marcador são arredondadas (~100 m) por privacidade.
  PostModel toPostModel({
    required String id,
    required String userId,
    required String userName,
    required DateTime agora,
    String? photoUrl,
    String? ownerAvatar,
  }) {
    final pos =
        position ?? (lat: AppConstants.defaultLat, lng: AppConstants.defaultLng);
    final raca = breed.trim().isEmpty ? PetOptions.racaPadrao : breed.trim();
    final cores = colors.toList();
    return PostModel(
      id: id,
      userId: userId,
      userName: userName,
      type: type,
      petName:
          type == PostType.lost ? petNameController.text.trim() : 'Sem nome',
      description: descriptionController.text.trim(),
      tags: [species, raca, size, ...cores],
      lastSeenAddress: addressController.text.trim(),
      latitude: LocationService.arredondar(pos.lat),
      longitude: LocationService.arredondar(pos.lng),
      photoUrl: photoUrl,
      createdAt: agora,
      eventAt: eventAt(agora),
      breed: raca,
      species: species,
      size: size,
      sex: sex,
      colors: cores,
      points: 0,
      helpersCount: 0,
      sightingsCount: 0,
      ownerAvatar: ownerAvatar,
      traits: traits.toList(),
    );
  }

  void dispose() {
    petNameController.dispose();
    descriptionController.dispose();
    addressController.dispose();
  }
}

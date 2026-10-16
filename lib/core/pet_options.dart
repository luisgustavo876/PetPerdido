import 'package:flutter/material.dart';

/// Opções fixas sobre o pet (espécie, cor, raça, porte...), usadas no\n/// formulário de criar post e nos filtros.
class PetOptions {
  PetOptions._();

  static const especies = {'Cão': '🐶', 'Gato': '🐱'};

  /// Cores do pet e as cores da bolinha de cada uma
  /// (mais de uma cor = bolinha dividida).
  static const cores = <String, List<Color>>{
    'Preto': [Color(0xFF212121)],
    'Branco': [Color(0xFFFFFFFF)],
    'Caramelo': [Color(0xFFC68642)],
    'Marrom': [Color(0xFF6D4C41)],
    'Cinza': [Color(0xFF9E9E9E)],
    'Dourado': [Color(0xFFE0B04B)],
    'Tricolor': [Color(0xFF212121), Color(0xFFC68642), Color(0xFFFFFFFF)],
    'Malhado': [Color(0xFF212121), Color(0xFFFFFFFF)],
  };
  static const maxCores = 2;

  static const racaPadrao = 'Sem raça definida';
  static const racas = {
    'Cão': [
      racaPadrao,
      'Vira-lata caramelo',
      'Beagle',
      'Border Collie',
      'Bulldog',
      'Dachshund (Salsicha)',
      'Golden Retriever',
      'Husky Siberiano',
      'Labrador',
      'Lhasa Apso',
      'Pastor Alemão',
      'Pinscher',
      'Pit Bull',
      'Poodle',
      'Rottweiler',
      'Shih Tzu',
      'Spitz Alemão (Lulu)',
      'Yorkshire',
    ],
    'Gato': [
      racaPadrao,
      'Angorá',
      'Bengal',
      'British Shorthair',
      'Maine Coon',
      'Persa',
      'Ragdoll',
      'Siamês',
      'Sphynx',
    ],
  };

  /// Porte e a dica de peso mostrada embaixo.
  static const portes = {
    'Pequeno': 'até 10 kg',
    'Médio': '10 a 25 kg',
    'Grande': 'mais de 25 kg',
  };

  static const sexos = ['Macho', 'Fêmea'];

  static const caracteristicas = [
    'Dócil',
    'Assustado',
    'Com Coleira',
    'Sem Coleira',
    'Castrado',
    'Ferido',
    'Brincalhão',
    'Olhos Azuis',
  ];

  /// Texto genérico que não serve como endereço do post.
  static const enderecoGenerico = 'Localização atual';
}

/// "15/10/2026 às 14:32".
String formatarDataHora(DateTime d) {
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(d.day)}/${dois(d.month)}/${d.year} às ${dois(d.hour)}:${dois(d.minute)}';
}

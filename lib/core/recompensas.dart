import 'package:flutter/material.dart';

/// Recompensa do catálogo. Os parceiros são EXEMPLOS (expansão futura do
/// projeto): nomes genéricos, sem marcas reais.
class Recompensa {
  final String id;
  final String titulo;
  final String descricao;
  final int custo;
  final IconData icone;
  final Color cor;

  const Recompensa({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.custo,
    required this.icone,
    required this.cor,
  });

  static const parceiroExemplo = 'Exemplo de parceria';
}

/// Catálogo de recompensas de demonstração.
const catalogoRecompensas = [
  Recompensa(
    id: 'kit_plaquinha',
    titulo: 'Plaquinha de identificação',
    descricao: 'Plaquinha com nome e telefone para a coleira.',
    custo: 50,
    icone: Icons.badge_outlined,
    cor: Color(0xFF0EA5E9),
  ),
  Recompensa(
    id: 'banho',
    titulo: 'Banho completo',
    descricao: 'Banho em pet shop parceiro da região.',
    custo: 100,
    icone: Icons.shower_outlined,
    cor: Color(0xFF2563EB),
  ),
  Recompensa(
    id: 'racao',
    titulo: 'Saco de ração 10 kg',
    descricao: 'Ração para cães ou gatos em loja parceira.',
    custo: 150,
    icone: Icons.inventory_2_outlined,
    cor: Color(0xFFD97706),
  ),
  Recompensa(
    id: 'consulta',
    titulo: 'Consulta veterinária',
    descricao: 'Consulta de rotina em clínica parceira.',
    custo: 250,
    icone: Icons.medical_services_outlined,
    cor: Color(0xFF16A34A),
  ),
  Recompensa(
    id: 'castracao',
    titulo: 'Desconto em castração',
    descricao: 'Desconto em castração em clínica parceira.',
    custo: 300,
    icone: Icons.pets_outlined,
    cor: Color(0xFF7C3AED),
  ),
];

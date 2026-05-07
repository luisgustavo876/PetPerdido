import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/post_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// Tela de criação de postagem.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  PostType _selectedType = PostType.lost;
  bool _isLoading = false;

  final _petNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  final Set<String> _selectedTags = {};

  static const _availableTags = [
    'Pelagem curta', 'Pelagem longa', 'Sem pelo',
    'Pequeno', 'Médio', 'Grande',
    'Preto', 'Branco', 'Marrom', 'Amarelo', 'Cinza', 'Tricolor',
    'Com coleira', 'Sem coleira',
    'Cão', 'Gato', 'Ave',
  ];

  @override
  void dispose() {
    _petNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _onPublish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos uma característica')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Salvar no Firestore nas próximas iterações
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post publicado com sucesso!'),
          backgroundColor: AppColors.tagFound,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Post')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Nome do pet (opcional)',
              hint: 'Ex: Luna, Thor...',
              controller: _petNameController,
              prefixIcon: Icons.pets,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Descrição',
              hint: 'Descreva o pet e as circunstâncias...',
              controller: _descriptionController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                if (v == null || v.trim().length < 10) {
                  return 'Descreva com ao menos 10 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Local onde foi visto por último',
              hint: 'Ex: Rua das Flores, 123 - Centro',
              controller: _addressController,
              prefixIcon: Icons.location_on_outlined,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o local' : null,
              suffixWidget: IconButton(
                icon: const Icon(Icons.my_location, color: AppColors.primary),
                onPressed: () {
                  // TODO: Preencher com GPS nas próximas iterações
                  _addressController.text = 'Localização atual';
                },
                tooltip: 'Usar localização atual',
              ),
            ),
            const SizedBox(height: 24),
            _buildTagSelector(),
            const SizedBox(height: 24),
            _buildAddPhotoButton(),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Publicar',
              onPressed: _onPublish,
              isLoading: _isLoading,
              icon: Icons.send_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de postagem',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: PostType.values.map((type) {
            final isSelected = _selectedType == type;
            final color = _colorForType(type);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? color : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : AppColors.divider,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _iconForType(type),
                          color: isSelected ? Colors.white : color,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _shortLabel(type),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTagSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Características do animal',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        const Text(
          'Selecione todas que se aplicam',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
              selectedColor: AppColors.primaryLight,
              checkmarkColor: AppColors.primaryDark,
              labelStyle: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.primaryDark : AppColors.onSurface,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleção de foto — próxima iteração')),
        );
      },
      icon: const Icon(Icons.add_photo_alternate_outlined),
      label: const Text('Adicionar Foto'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Color _colorForType(PostType type) {
    switch (type) {
      case PostType.lost: return AppColors.tagLost;
      case PostType.found: return AppColors.tagFound;
      case PostType.sighted: return AppColors.tagSighted;
    }
  }

  IconData _iconForType(PostType type) {
    switch (type) {
      case PostType.lost: return Icons.search;
      case PostType.found: return Icons.home_outlined;
      case PostType.sighted: return Icons.visibility_outlined;
    }
  }

  String _shortLabel(PostType type) {
    switch (type) {
      case PostType.lost: return 'Perdi\nmeu Pet';
      case PostType.found: return 'Achei\num Pet';
      case PostType.sighted: return 'Avistei\num Pet';
    }
  }
}

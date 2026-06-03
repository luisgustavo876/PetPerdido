import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_colors.dart';
import '../../models/post_model.dart';
import '../../models/app_state.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final AppState _appState = AppState();
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 1;
  PostType _selectedType = PostType.lost;
  XFile? _selectedImageFile;   // Arquivo real selecionado
  Uint8List? _imageBytes;       // Bytes para preview (funciona na web e mobile)
  
  // Dados do form
  final _petNameController = TextEditingController();
  final _descController = TextEditingController();
  final _breedController = TextEditingController(text: 'Sem Raça Definida');
  final _addressController = TextEditingController(text: 'Vila Barth, Itapetininga');
  
  String _selectedSpecies = 'Cão';
  String _selectedSize = 'Médio';
  String _selectedSex = 'Macho';
  
  bool _notifyRadius = true;
  double _notificationRadius = 2.0; // 2km
  bool _offerReward = false;
  double _rewardPoints = 100.0;
  bool _isLoading = false;

  final List<String> _availableTraits = [
    'Dócil', 'Assustado', 'Com Coleira', 'Sem Coleira',
    'Castrado', 'Ferido', 'Brincalhão', 'Olhos Azuis'
  ];
  final Set<String> _selectedTraits = {'Sem Coleira'};

  @override
  void dispose() {
    _petNameController.dispose();
    _descController.dispose();
    _breedController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Abre o seletor de imagens (galeria ou câmera).
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageFile = image;
        _imageBytes = bytes;
      });
    }
  }

  void _onPublish() async {
    if (_descController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, descreva o pet com pelo menos 10 caracteres.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Coordenadas aproximadas em Itapetininga, SP
    final double lat = -23.5897 + (DateTime.now().millisecond % 100) * 0.0003;
    final double lng = -48.0533 + (DateTime.now().microsecond % 100) * 0.0003;

    // ID único do post (gerado antes do upload para usar como pasta no Storage)
    final String postId = DateTime.now().millisecondsSinceEpoch.toString();

    // Upload da foto para o Firebase Storage (se houver)
    String? photoUrl;
    if (_selectedImageFile != null) {
      try {
        photoUrl = await StorageService.uploadPostImage(_selectedImageFile!, postId);
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao enviar a foto. Tente novamente.')),
          );
        }
        return;
      }
    }

    final user = AuthService.currentUser;
    final newPost = PostModel(
      id: postId,
      userId: user?.uid ?? 'anon',
      userName: AuthService.currentUserName,
      type: _selectedType,
      petName: _selectedType == PostType.lost ? _petNameController.text.trim() : 'Sem nome',
      description: _descController.text.trim(),
      tags: [_selectedSpecies, _breedController.text.trim(), _selectedSize],
      lastSeenAddress: _addressController.text.trim(),
      latitude: lat,
      longitude: lng,
      photoUrl: photoUrl,  // URL real do Firebase Storage (ou null)
      createdAt: DateTime.now(),
      breed: _breedController.text.trim(),
      species: _selectedSpecies,
      size: _selectedSize,
      sex: _selectedSex,
      points: 0,
      helpersCount: 0,
      sightingsCount: 0,
      ownerAvatar: user?.photoURL,
      traits: _selectedTraits.toList(),
    );

    await _appState.addPost(newPost);

    setState(() => _isLoading = false);

    if (mounted) {
      _showSuccessDialog(context);
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Post Publicado!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sua postagem foi enviada com sucesso para a rede de moradores e já está visível no mapa!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Fecha Dialog
                      Navigator.pop(context); // Volta para o mapa/feed
                    },
                    child: const Text('Ótimo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Criar Postagem'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.onSurface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _buildProgressStepper(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_currentStep == 1) _buildStep1() else _buildStep2(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStepper() {
    return Row(
      children: List.generate(2, (index) {
        final step = index + 1;
        final isActive = _currentStep >= step;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.grey[200],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStep1() {
    final types = [
      {
        'type': PostType.lost,
        'title': 'SOS: Perdi meu pet',
        'desc': 'Seu animal de estimação fugiu ou desapareceu de casa.',
        'color': AppColors.tagLost,
        'icon': Icons.report_problem_outlined,
      },
      {
        'type': PostType.sighted,
        'title': 'Avistei um pet solto',
        'desc': 'Você viu um pet que parece estar perdido, mas não conseguiu acolhê-lo.',
        'color': AppColors.tagSighted,
        'icon': Icons.visibility_outlined,
      },
      {
        'type': PostType.found,
        'title': 'Estou com um pet sem dono',
        'desc': 'Você resgatou ou acolheu temporariamente um pet perdido.',
        'color': AppColors.tagFound,
        'icon': Icons.home_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Qual o motivo da postagem?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
        const SizedBox(height: 6),
        const Text(
          'Selecione uma das opções abaixo para iniciarmos o preenchimento do anúncio.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Column(
          children: types.map((item) {
            final type = item['type'] as PostType;
            final isSelected = _selectedType == type;
            final color = item['color'] as Color;

            return GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.04) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey[200]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.12) : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: isSelected ? color : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? color : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['desc'] as String,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sobre o Pet',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
        const SizedBox(height: 6),
        const Text(
          'Forneça as características básicas do animal para facilitar a identificação visual.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 20),

        // Box de foto com preview real
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
            ),
            child: _imageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Toque para escolher uma foto',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Câmera ou galeria',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),

        // Nome do Pet (Apenas se for 'lost')
        if (_selectedType == PostType.lost) ...[
          const Text('Nome do Pet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _petNameController,
            decoration: InputDecoration(
              hintText: 'Ex: Pipoca, Max, Lola...',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Espécie (Cão/Gato)
        const Text('Espécie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: ['Cão', 'Gato'].map((species) {
            final isSelected = _selectedSpecies == species;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedSpecies = species),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[200]!),
                  ),
                  child: Text(
                    species,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Raça
        const Text('Raça', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: _breedController,
          decoration: InputDecoration(
            hintText: 'Ex: Golden Retriever, Siamesa, Vira-lata...',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          ),
        ),
        const SizedBox(height: 16),

        // Porte (Pequeno, Médio, Grande)
        const Text('Porte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: ['Pequeno', 'Médio', 'Grande'].map((size) {
            final isSelected = _selectedSize == size;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedSize = size),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[200]!),
                  ),
                  child: Text(
                    size,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Sexo (Macho, Fêmea)
        const Text('Sexo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: ['Macho', 'Fêmea'].map((sex) {
            final isSelected = _selectedSex == sex;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedSex = sex),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[200]!),
                  ),
                  child: Text(
                    sex,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Características adicionais chips
        const Text('Outras Características', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _availableTraits.map((trait) {
            final isSelected = _selectedTraits.contains(trait);
            return FilterChip(
              label: Text(trait),
              selected: isSelected,
              selectedColor: AppColors.primary.withOpacity(0.12),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(color: isSelected ? AppColors.primary : Colors.black87, fontSize: 11),
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedTraits.add(trait);
                  } else {
                    _selectedTraits.remove(trait);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Descrição do Pet
        const Text('Descrição Detalhada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: _descController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Ex: Fale sobre manchas, coleira, marcas específicas do pet...',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          ),
        ),
        const SizedBox(height: 16),

        // Endereço ou bairro (movido do antigo Step 3)
        const Text('Endereço ou Bairro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: _addressController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.location_on, color: AppColors.primary),
            hintText: 'Ex: Rua das Flores, Vila Barth...',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Step 3 removido — localização agora está no Step 2
  // Notificação de vizinhos é automática (não configurável pelo usuário)
  // Recompensa em dinheiro não é funcionalidade do app

  // Mantido apenas para evitar erros de referência — não é usado
  Widget _buildStep3Unused() {
    final int estimatedNeighbors = (_notificationRadius * 260).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Localização & Alertas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
        const SizedBox(height: 6),
        const Text(
          'Configure a localização de busca e envie notificações para moradores vizinhos.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 20),

        // Endereço
        const Text('Endereço ou Bairro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: _addressController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.location_on, color: AppColors.primary),
            hintText: 'Ex: Rua das Flores, Vila Barth...',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          ),
        ),
        const SizedBox(height: 20),

        // Mapa estático simulado de Itapetininga
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            image: const DecorationImage(
              image: AssetImage('assets/images/map.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child: Icon(Icons.location_pin, color: AppColors.primary, size: 36),
          ),
        ),
        const SizedBox(height: 20),

        // Notificar vizinhos raio
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                value: _notifyRadius,
                onChanged: (val) => setState(() => _notifyRadius = val ?? true),
                title: const Text('Notificar vizinhos na área', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Dispara push e e-mail imediatamente.', style: TextStyle(fontSize: 11)),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              if (_notifyRadius) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Raio de Alerta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('${_notificationRadius.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                  ],
                ),
                Slider(
                  value: _notificationRadius,
                  min: 1.0,
                  max: 5.0,
                  divisions: 8,
                  activeColor: AppColors.primary,
                  inactiveColor: Colors.grey[200],
                  onChanged: (val) => setState(() => _notificationRadius = val),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: Colors.teal, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Alerta enviado a ~$estimatedNeighbors moradores ativos!',
                        style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Oferecer recompensa (apenas se for 'lost')
        if (_selectedType == PostType.lost) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  value: _offerReward,
                  onChanged: (val) => setState(() => _offerReward = val),
                  title: const Text('Oferecer Recompensa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Estimula o engajamento dos vizinhos na busca.', style: TextStyle(fontSize: 11)),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                if (_offerReward) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Valor em Pontos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('${_rewardPoints.toInt()} pts', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 14)),
                    ],
                  ),
                  Slider(
                    value: _rewardPoints,
                    min: 50.0,
                    max: 300.0,
                    divisions: 5,
                    activeColor: Colors.amber,
                    inactiveColor: Colors.grey[200],
                    onChanged: (val) => setState(() => _rewardPoints = val),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 1) ...[
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => setState(() => _currentStep--),
                  child: const Text('Voltar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
                          _onPublish();
                        }
                      },
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _currentStep == 2 ? 'Publicar Anúncio' : 'Avançar',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_colors.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/post_service.dart';
import '../../services/storage_service.dart';

/// Em que etapa da publicação estamos — usada para escolher a mensagem de erro.
enum _EtapaPublicacao { upload, salvar }

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  int _currentStep = 1;
  PostType _selectedType = PostType.lost;
  XFile? _selectedImageFile;   // Arquivo real selecionado
  Uint8List? _imageBytes;       // Bytes para preview (funciona na web e mobile)
  
  // Dados do form
  final _petNameController = TextEditingController();
  final _descController = TextEditingController();
  final _breedController = TextEditingController(text: 'Sem Raça Definida');
  final _addressController = TextEditingController();

  String _selectedSpecies = 'Cão';
  String _selectedSize = 'Médio';
  String _selectedSex = 'Macho';

  /// Coordenadas do GPS, quando o usuário toca em "Usar minha localização
  /// atual". Enquanto não for null, têm prioridade sobre o endereço digitado.
  ({double lat, double lng})? _gpsPosition;
  bool _isLocating = false;
  bool _isLoading = false;

  /// ID do post, gerado uma vez quando a tela abre. Toda tentativa de
  /// publicar usa o mesmo id: tentar de novo sobrescreve, não duplica.
  late final String _postId;

  static const _timeout = Duration(seconds: 30);
  static const _msgConexaoLenta =
      'Conexão lenta. Confira no feed se o post apareceu antes de tentar de novo.';

  static const _msgSemLocalizacao =
      'Não encontramos esse endereço. Ajuste o endereço ou use sua localização atual.';

  /// Foto é obrigatória em Perdi e Achei (opcional em Avistei).
  bool get _fotoObrigatoria => _selectedType != PostType.sighted;

  final List<String> _availableTraits = [
    'Dócil', 'Assustado', 'Com Coleira', 'Sem Coleira',
    'Castrado', 'Ferido', 'Brincalhão', 'Olhos Azuis'
  ];
  final Set<String> _selectedTraits = {'Sem Coleira'};

  @override
  void initState() {
    super.initState();
    _postId = DateTime.now().millisecondsSinceEpoch.toString();
  }

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

  void _mostrarMensagem(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Botão "Usar minha localização atual": GPS + bairro por geocoding reverso.
  Future<void> _usarLocalizacaoAtual() async {
    setState(() => _isLocating = true);
    try {
      final pos = await LocationService.posicaoAtual();
      final bairro = await LocationService.bairroDe(pos.lat, pos.lng);
      if (!mounted) return;
      setState(() {
        _gpsPosition = pos;
        if (bairro != null) _addressController.text = bairro;
      });
      if (bairro == null) {
        // Ex.: na Web o geocoding não funciona — a posição vale, falta o nome.
        _mostrarMensagem(
            'Localização obtida. Digite o bairro no campo de endereço.');
      }
    } on LocationException catch (e) {
      if (mounted) _mostrarMensagem(e.message);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// Regras de negócio do post. Retorna a mensagem de erro ou null.
  String? _validar() {
    if (_selectedType == PostType.lost &&
        _petNameController.text.trim().isEmpty) {
      return 'Informe o nome do pet.';
    }
    if (_fotoObrigatoria && _selectedImageFile == null) {
      return 'A foto é obrigatória para "${_selectedType.label}".';
    }
    if (_descController.text.trim().length < 10) {
      return 'Descreva o pet com pelo menos 10 caracteres.';
    }
    if (_addressController.text.trim().isEmpty) {
      return 'Informe o endereço ou bairro, ou use sua localização atual.';
    }
    return null;
  }

  /// Mensagem de erro em português conforme a etapa e o código do Firebase.
  String _mensagemDeErro(Object erro, _EtapaPublicacao etapa) {
    if (erro is TimeoutException) return _msgConexaoLenta;
    final codigo = erro is FirebaseException ? erro.code : '';
    if (const ['unavailable', 'network-request-failed', 'retry-limit-exceeded']
        .contains(codigo)) {
      return 'Sem conexão com a internet. Tente novamente.';
    }
    if (codigo == 'permission-denied' || codigo == 'unauthorized') {
      return etapa == _EtapaPublicacao.upload
          ? 'Sem permissão para enviar a foto. Entre na conta novamente.'
          : 'Sem permissão para publicar. Entre na conta novamente.';
    }
    return etapa == _EtapaPublicacao.upload
        ? 'Falha ao enviar a foto. Tente novamente.'
        : 'Não foi possível publicar. Tente novamente.';
  }

  Future<void> _onPublish() async {
    final erro = _validar();
    if (erro != null) {
      _mostrarMensagem(erro);
      return;
    }

    final user = AuthService.currentUser;
    if (user == null) {
      _mostrarMensagem('Entre na sua conta para publicar.');
      return;
    }

    setState(() => _isLoading = true);
    var etapa = _EtapaPublicacao.upload;
    try {
      // Coordenadas: GPS, se o usuário usou; senão, o endereço digitado.
      final pos = _gpsPosition ??
          await LocationService.coordenadasDe(_addressController.text.trim());
      if (pos == null) {
        if (mounted) _mostrarMensagem(_msgSemLocalizacao);
        return;
      }

      // Privacidade: arredonda para ~100 m (GPS ou endereço). O geohash é
      // calculado pelo PostModel a partir destes valores já arredondados.
      final lat = LocationService.arredondar(pos.lat);
      final lng = LocationService.arredondar(pos.lng);

      String? photoUrl;
      if (_selectedImageFile != null) {
        photoUrl = await StorageService.uploadPostImage(
                _selectedImageFile!, _postId)
            .timeout(_timeout);
      }

      etapa = _EtapaPublicacao.salvar;
      await PostService.createPost(PostModel(
        id: _postId,
        userId: user.uid,
        userName: AuthService.currentUserName,
        type: _selectedType,
        petName: _selectedType == PostType.lost
            ? _petNameController.text.trim()
            : 'Sem nome',
        description: _descController.text.trim(),
        tags: [_selectedSpecies, _breedController.text.trim(), _selectedSize],
        lastSeenAddress: _addressController.text.trim(),
        latitude: lat,
        longitude: lng,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
        breed: _breedController.text.trim(),
        species: _selectedSpecies,
        size: _selectedSize,
        sex: _selectedSex,
        points: 0,
        helpersCount: 0,
        sightingsCount: 0,
        ownerAvatar: user.photoURL,
        traits: _selectedTraits.toList(),
      )).timeout(_timeout);

      if (mounted) _showSuccessDialog(context);
    } catch (e) {
      debugPrint('Erro ao publicar post ($etapa): $e');
      if (mounted) _mostrarMensagem(_mensagemDeErro(e, etapa));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      body: Column(
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
                  color: isSelected ? color.withValues(alpha: 0.04) : Colors.grey[50],
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
                        color: isSelected ? color.withValues(alpha: 0.12) : Colors.grey[200],
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
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text(
                        'Toque para escolher uma foto',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fotoObrigatoria ? 'Obrigatória' : 'Opcional',
                        style: TextStyle(
                          color: _fotoObrigatoria ? AppColors.primary : Colors.grey,
                          fontSize: 11,
                          fontWeight: _fotoObrigatoria ? FontWeight.w600 : FontWeight.normal,
                        ),
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
              selectedColor: AppColors.primary.withValues(alpha: 0.12),
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

        // Onde o pet foi visto: endereço digitado OU localização do GPS
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
        const SizedBox(height: 8),
        if (_gpsPosition == null)
          TextButton.icon(
            onPressed: _isLocating ? null : _usarLocalizacaoAtual,
            icon: _isLocating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, size: 18),
            label: Text(_isLocating ? 'Obtendo localização...' : 'Usar minha localização atual'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          )
        else
          // Deixa claro que o GPS está sendo usado, com opção de desfazer.
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Usando sua localização atual no mapa',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _gpsPosition = null),
                  child: const Text('Remover'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
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

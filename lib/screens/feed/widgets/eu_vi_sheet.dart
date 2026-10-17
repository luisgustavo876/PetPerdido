import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/app_colors.dart';
import '../../../core/pet_options.dart';
import '../../../models/sighting_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/location_service.dart';
import '../../../services/post_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/seletor_imagem.dart';

/// Formulário "Eu vi este pet" (bottom sheet). Grava em
/// posts/{postId}/sightings/{uid}. Retorna true se registrou.
class EuViSheet extends StatefulWidget {
  final String postId;

  const EuViSheet({super.key, required this.postId});

  /// Abre o formulário. Retorna true se o avistamento foi registrado.
  static Future<bool> abrir(BuildContext context, String postId) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => EuViSheet(postId: postId),
    );
    return ok ?? false;
  }

  @override
  State<EuViSheet> createState() => _EuViSheetState();
}

class _EuViSheetState extends State<EuViSheet> {
  static const _timeout = Duration(seconds: 30);
  static const _msgSemBairro = 'Informe o bairro onde você viu o pet';

  final _bairroController = TextEditingController();
  final _notasController = TextEditingController();

  /// Posição do GPS (sem arredondar). Descartada se o usuário trocar o
  /// bairro que o GPS preencheu.
  ({double lat, double lng})? _pos;
  String? _bairroDoGps;

  bool _localizando = false;
  bool _enviando = false;
  XFile? _foto;
  Uint8List? _fotoBytes;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _usarLocalizacao(); // preenche o bairro sozinho, como no criar post
  }

  @override
  void dispose() {
    _bairroController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _usarLocalizacao() async {
    setState(() {
      _localizando = true;
      _erro = null;
    });
    try {
      final pos = await LocationService.posicaoAtual();
      final bairro = await LocationService.bairroDe(pos.lat, pos.lng);
      if (!mounted) return;
      setState(() {
        _pos = pos;
        _bairroDoGps = bairro;
        _bairroController.text = bairro ?? '';
        if (bairro == null) _erro = _msgSemBairro;
      });
    } on LocationException catch (e) {
      if (mounted) setState(() => _erro = '${e.message} Digite o bairro.');
    } finally {
      if (mounted) setState(() => _localizando = false);
    }
  }

  void _editouBairro(String texto) {
    setState(() {
      _erro = null;
      // O GPS preencheu um bairro e a pessoa trocou: a posição não vale mais.
      if (_bairroDoGps != null && texto.trim() != _bairroDoGps) {
        _pos = null;
        _bairroDoGps = null;
      }
    });
  }

  Future<void> _escolherFoto() async {
    try {
      final foto = await SeletorImagem.escolher(context);
      if (foto == null) return;
      final bytes = await foto.readAsBytes();
      if (mounted) {
        setState(() {
          _foto = foto;
          _fotoBytes = bytes;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível abrir a câmera ou a galeria.');
      }
    }
  }

  /// O que ainda falta preencher (null = pode registrar).
  String? get _falta => SightingModel.oQueFalta(
        bairro: _bairroController.text,
        descricao: _notasController.text,
        bairroGenerico: PetOptions.enderecoGenerico,
      );

  Future<void> _registrar() async {
    final falta = _falta;
    if (falta != null) {
      setState(() => _erro = falta);
      return;
    }
    final bairro = _bairroController.text.trim();
    final user = AuthService.currentUser;
    if (user == null) {
      setState(() => _erro = 'Entre na sua conta para registrar.');
      return;
    }

    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      // Coordenadas: GPS ou o bairro digitado. Se não achar, salva sem.
      final pos = _pos ?? await LocationService.coordenadasDe(bairro);

      String? fotoUrl;
      if (_foto != null) {
        fotoUrl = await StorageService.uploadSightingImage(
                _foto!, widget.postId, user.uid)
            .timeout(_timeout);
      }

      await PostService.registrarAvistamento(
        widget.postId,
        SightingModel(
          userId: user.uid,
          userName: AuthService.currentUserName,
          address: bairro,
          lat: pos == null ? null : LocationService.arredondar(pos.lat),
          lng: pos == null ? null : LocationService.arredondar(pos.lng),
          notes: _notasController.text.trim(),
          photoUrl: fotoUrl,
          createdAt: DateTime.now(),
        ),
      ).timeout(_timeout);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('EuViSheet: falha ao registrar: $e');
      if (!mounted) return;
      final codigo = e is FirebaseException ? e.code : '';
      setState(() => _erro = switch (codigo) {
            'permission-denied' =>
              'Não foi possível registrar. Talvez você já tenha registrado um avistamento neste post.',
            'unavailable' || 'network-request-failed' =>
              'Sem conexão com a internet. Tente novamente.',
            _ when e is TimeoutException =>
              'Conexão lenta. Confira se o avistamento apareceu antes de tentar de novo.',
            _ => 'Não foi possível registrar. Tente novamente.',
          });
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final falta = _falta;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Registrar avistamento',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sua informação ajuda o tutor a refazer o caminho do pet. '
                'Mostramos só o bairro.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              const Text('Onde você viu?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _bairroController,
                onChanged: _editouBairro,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Ex.: Centro, Itapetininga',
                  prefixIcon: const Icon(Icons.location_on_outlined,
                      color: AppColors.primary, size: 20),
                  suffixIcon: _localizando
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          tooltip: 'Usar minha localização atual',
                          icon: const Icon(Icons.my_location, size: 20),
                          onPressed: _usarLocalizacao,
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('O que você viu?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _notasController,
                onChanged: (_) => setState(() => _erro = null),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ex.: estava assustado e correu para a praça.',
                  helperText:
                      'Obrigatório, mínimo de ${SightingModel.minDescricao} caracteres.',
                ),
              ),
              const SizedBox(height: 16),
              _secaoFoto(),
              if (_erro != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _erro!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Desabilitado enquanto faltar bairro ou descrição.
              ElevatedButton(
                onPressed: _enviando || falta != null ? null : _registrar,
                child: _enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Registrar avistamento'),
              ),
              if (falta != null && !_localizando) ...[
                const SizedBox(height: 8),
                Text(
                  falta,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _secaoFoto() {
    if (_fotoBytes == null) {
      return OutlinedButton.icon(
        onPressed: _escolherFoto,
        icon: const Icon(Icons.add_a_photo_outlined, size: 18),
        label: const Text('Anexar foto (opcional)'),
      );
    }
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(_fotoBytes!, width: 88, height: 88, fit: BoxFit.cover),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: _escolherFoto,
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Trocar foto'),
              ),
              TextButton.icon(
                onPressed: () => setState(() {
                  _foto = null;
                  _fotoBytes = null;
                }),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remover'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

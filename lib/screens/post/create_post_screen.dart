import 'dart:async';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/pontos_service.dart';
import '../../services/post_service.dart';
import '../../services/storage_service.dart';
import 'post_draft.dart';
import 'widgets/post_form_ui.dart';
import 'widgets/step_foto.dart';
import 'widgets/step_local.dart';
import 'widgets/step_pet.dart';
import 'widgets/step_revisao.dart';
import 'widgets/step_tipo.dart';

/// Em que etapa da publicação estamos — usada para escolher a mensagem de erro.
enum _EtapaPublicacao { upload, salvar }

/// Criar post em 5 etapas: Tipo · Foto · Pet · Local · Revisar.
///
/// O estado do formulário fica no [PostDraft]; as etapas (em widgets/)
/// alteram o rascunho e chamam [_alterou], que faz o setState aqui.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _draft = PostDraft();

  /// ID do post, gerado uma vez quando a tela abre. Toda tentativa de
  /// publicar usa o mesmo id: tentar de novo sobrescreve, não duplica.
  late final String _postId;

  static const _timeout = Duration(seconds: 30);
  static const _msgConexaoLenta =
      'Conexão lenta. Confira no feed se o post apareceu antes de tentar de novo.';

  int _etapa = 0;
  bool _avancando = true; // direção da animação entre etapas
  String? _erro; // erro de validação mostrado na própria tela
  bool _isLoading = false;

  bool get _ultimaEtapa => _etapa == PostDraft.totalEtapas - 1;

  @override
  void initState() {
    super.initState();
    _postId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  /// Qualquer alteração em uma etapa apaga o erro mostrado.
  void _alterou() => setState(() => _erro = null);

  void _irPara(int etapa) {
    FocusScope.of(context).unfocus();
    setState(() {
      _avancando = etapa > _etapa;
      _etapa = etapa;
      _erro = null;
    });
  }

  void _avancar() {
    if (_ultimaEtapa) {
      _onPublish();
      return;
    }
    final erro = _draft.validarEtapa(_etapa, DateTime.now());
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    _irPara(_etapa + 1);
  }

  void _voltar() {
    if (_etapa > 0) _irPara(_etapa - 1);
  }

  // ---------------------------------------------------------------------------
  // Publicação
  // ---------------------------------------------------------------------------

  void _mostrarMensagem(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
    // Confere todas as etapas; se alguma falhar, volta para ela.
    final agora = DateTime.now();
    final invalida = _draft.primeiraEtapaInvalida(agora);
    if (invalida != null) {
      _irPara(invalida);
      setState(() => _erro = _draft.validarEtapa(invalida, agora));
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
      String? photoUrl;
      final foto = _draft.imageFile;
      if (foto != null) {
        photoUrl =
            await StorageService.uploadPostImage(foto, _postId).timeout(_timeout);
      }

      etapa = _EtapaPublicacao.salvar;
      // Coordenadas do marcador, arredondadas (~100 m) dentro do toPostModel.
      final post = _draft.toPostModel(
        id: _postId,
        userId: user.uid,
        userName: AuthService.currentUserName,
        agora: DateTime.now(),
        photoUrl: photoUrl,
        ownerAvatar: user.photoURL,
      );
      await PostService.createPost(post).timeout(_timeout);
      // Achei +30, Avistei +10 (uma vez por post, mesmo tentando de novo).
      await PontosService.ganharPorPost(post);

      if (mounted) {
        _showSuccessDialog(context, PontosService.pontosPorPost(post.type));
      }
    } catch (e) {
      debugPrint('Erro ao publicar post ($etapa): $e');
      if (mounted) _mostrarMensagem(_mensagemDeErro(e, etapa));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(BuildContext context, int pontos) {
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
                  'Sua postagem já está no mapa e no feed. Quem estiver perto e '
                  'com os alertas ligados será avisado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                if (pontos > 0) ...[
                  const SizedBox(height: 16),
                  Text(
                    '+$pontos pontos!',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.tagFound,
                    ),
                  ),
                ],
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

  // ---------------------------------------------------------------------------
  // Tela
  // ---------------------------------------------------------------------------

  Widget _conteudoDaEtapa() {
    switch (_etapa) {
      case 0:
        return StepTipo(draft: _draft, onChanged: _alterou);
      case 1:
        return StepFoto(draft: _draft, onChanged: _alterou);
      case 2:
        return StepPet(draft: _draft, onChanged: _alterou);
      case 3:
        return StepLocal(draft: _draft, onChanged: _alterou);
      default:
        return StepRevisao(
          draft: _draft,
          userName: AuthService.currentUserName,
          onEditar: _irPara,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // O "voltar" do aparelho volta uma etapa antes de sair da tela.
      canPop: _etapa == 0 && !_isLoading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isLoading) _voltar();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('Criar postagem'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: IndicadorEtapas(
              rotulos: PostDraft.rotulosEtapas,
              atual: _etapa,
              onVoltarPara: _irPara,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                layoutBuilder: (atual, anteriores) => Stack(
                  fit: StackFit.expand,
                  children: [...anteriores, if (atual != null) atual],
                ),
                transitionBuilder: (child, animacao) {
                  // Avançando: a nova etapa entra pela direita e a antiga sai
                  // pela esquerda. Voltando: o contrário.
                  final entrando = child.key == ValueKey(_etapa);
                  final dx = (_avancando == entrando) ? 0.08 : -0.08;
                  return FadeTransition(
                    opacity: animacao,
                    child: SlideTransition(
                      position: Tween(begin: Offset(dx, 0), end: Offset.zero)
                          .animate(animacao),
                      child: child,
                    ),
                  );
                },
                child: SingleChildScrollView(
                  key: ValueKey(_etapa),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  child: _conteudoDaEtapa(),
                ),
              ),
            ),
            _rodape(),
          ],
        ),
      ),
    );
  }

  Widget _rodape() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Erro da etapa, dentro da tela (não só em SnackBar).
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _erro == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AvisoErro(_erro!),
                    ),
            ),
            Row(
              children: [
                if (_etapa > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _voltar,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.divider),
                      ),
                      child: const Text('Voltar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _avancar,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(_ultimaEtapa ? 'Publicar anúncio' : 'Avançar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

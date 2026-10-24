import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../core/app_constants.dart';
import '../core/pet_options.dart';
import '../models/sugestao_ia.dart';
import 'auth_service.dart';

/// Erro da IA com mensagem pronta para mostrar ao usuário.
class IAException implements Exception {
  final String mensagem;
  const IAException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Extração de metadados do pet (espécie, porte, cor...) com o Gemini.
///
/// O app chama a Cloud Function `analisarPet` (HTTPS, com o token do usuário
/// logado); a Function guarda a chave do Gemini num segredo do Firebase e
/// monta as instruções e o esquema da resposta. O app não tem chave nenhuma.
class AIService {
  static const _timeout = Duration(seconds: 45);

  /// Analisa a foto do pet. Lança [IAException] com a mensagem para o usuário.
  static Future<SugestaoIA> analisarFoto(Uint8List foto) async {
    final reduzida = await compute(reduzirFoto, foto);
    return _gerar({'imagem': base64Encode(reduzida), 'mime': 'image/jpeg'});
  }

  /// Analisa a descrição digitada (ex.: Avistei sem foto).
  static Future<SugestaoIA> analisarDescricao(String descricao) =>
      _gerar({'descricao': descricao});

  static Future<SugestaoIA> _gerar(Map<String, Object> pedido) async {
    final usuario = AuthService.currentUser;
    if (usuario == null) {
      throw const IAException('Entre na sua conta para usar a IA.');
    }

    final http.Response resposta;
    try {
      final token = await usuario.getIdToken();
      resposta = await http
          .post(
            Uri.parse(AppConstants.iaUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({...pedido, 'opcoes': opcoes}),
          )
          .timeout(_timeout);
    } catch (e) {
      debugPrint('AIService: falha ao chamar a IA: $e');
      throw IAException(mensagemDeErro(e));
    }

    if (resposta.statusCode != 200) {
      debugPrint('AIService: a IA respondeu ${resposta.statusCode}: '
          '${resposta.body}');
      throw IAException(mensagemDoStatus(resposta.statusCode));
    }

    String? texto;
    try {
      texto = (jsonDecode(resposta.body) as Map<String, dynamic>)['texto']
          as String?;
    } catch (_) {
      texto = null;
    }
    final sugestao = SugestaoIA.converter(texto);
    if (sugestao == null) {
      throw const IAException(
          'A IA não conseguiu identificar o pet. Preencha manualmente.');
    }
    if (sugestao.naoEhPet) {
      throw const IAException(
          'Não encontramos um cão ou gato. Confira a foto ou preencha manualmente.');
    }
    return sugestao;
  }

  /// Valores permitidos na resposta (a Function monta o esquema com eles).
  static Map<String, List<String>> get opcoes => {
        'especies': PetOptions.especies.keys.toList(),
        'portes': PetOptions.portes.keys.toList(),
        'cores': PetOptions.cores.keys.toList(),
        'caracteristicas': PetOptions.caracteristicas,
      };

  /// Mensagem para o usuário conforme a resposta da Function. Função pura.
  static String mensagemDoStatus(int status) => switch (status) {
        401 => 'Entre de novo na sua conta para usar a IA.',
        429 => 'A IA atingiu o limite de uso gratuito por agora. '
            'Tente mais tarde ou preencha manualmente.',
        400 || 413 => 'Não foi possível enviar isso para a IA. '
            'Tente outra foto ou preencha manualmente.',
        _ => 'A IA não conseguiu responder agora. '
            'Tente de novo ou preencha manualmente.',
      };

  /// Mensagem para falhas antes da resposta (tempo, internet). Função pura.
  static String mensagemDeErro(Object erro) {
    if (erro is TimeoutException) {
      return 'A IA demorou para responder. Confira a internet e tente de novo.';
    }
    return 'Não foi possível usar a IA agora (sem internet?). Preencha manualmente.';
  }
}

/// Reduz a foto para no máximo [AppConstants.iaMaxPixels] px no maior lado
/// e devolve um JPEG. Se não conseguir ler a imagem, devolve a original.
/// Função pura (roda fora da tela com `compute`).
Uint8List reduzirFoto(Uint8List original) {
  final imagem = img.decodeImage(original);
  if (imagem == null) return original;
  const maximo = AppConstants.iaMaxPixels;
  final maior = imagem.width > imagem.height ? imagem.width : imagem.height;
  final reduzida = maior <= maximo
      ? imagem
      : img.copyResize(
          imagem,
          width: imagem.width >= imagem.height ? maximo : null,
          height: imagem.height > imagem.width ? maximo : null,
          interpolation: img.Interpolation.average,
        );
  return Uint8List.fromList(img.encodeJpg(reduzida, quality: 80));
}

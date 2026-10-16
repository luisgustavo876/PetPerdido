import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../core/app_constants.dart';
import '../core/pet_options.dart';
import '../models/sugestao_ia.dart';

/// Erro da IA com mensagem pronta para mostrar ao usuário.
class IAException implements Exception {
  final String mensagem;
  const IAException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Extração de metadados do pet (espécie, porte, cor...) com o Gemini, pelo
/// Firebase AI Logic. A chamada passa pelo Firebase: o app não tem chave.
class AIService {
  static const _timeout = Duration(seconds: 30);

  static const _instrucoes = '''
Você ajuda um app de pets perdidos a descrever animais.
Analise somente o animal principal (cão ou gato). Ignore pessoas, roupas,
placas, textos e o fundo. Nunca descreva pessoas.
Se não houver cão nem gato, responda species "Indefinido" e deixe as listas vazias.
Use apenas os valores permitidos no esquema. Para cores, escolha no máximo 2
das opções. Para a raça, um nome curto em português ou "Sem raça definida"
se for mestiço ou incerto. Para características, só as que forem visíveis
(ou citadas, no caso de texto).''';

  static GenerativeModel get _modelo => FirebaseAI.googleAI().generativeModel(
        model: AppConstants.geminiModel,
        systemInstruction: Content.system(_instrucoes),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: _esquema,
          temperature: 0.2,
        ),
      );

  /// Saída estruturada: só valores das listas do app.
  static final _esquema = Schema.object(
    properties: {
      'species': Schema.enumString(
          enumValues: [...PetOptions.especies.keys, 'Indefinido']),
      'size': Schema.enumString(enumValues: PetOptions.portes.keys.toList()),
      'colors': Schema.array(
        items: Schema.enumString(enumValues: PetOptions.cores.keys.toList()),
        description: 'No máximo 2 cores.',
      ),
      'breed': Schema.string(description: 'Raça curta ou "Sem raça definida".'),
      'traits': Schema.array(
        items: Schema.enumString(enumValues: PetOptions.caracteristicas),
      ),
    },
  );

  /// Analisa a foto do pet. Lança [IAException] com a mensagem para o usuário.
  static Future<SugestaoIA> analisarFoto(Uint8List foto) async {
    final reduzida = await compute(reduzirFoto, foto);
    return _gerar(Content.multi([
      TextPart('Descreva o pet desta foto.'),
      InlineDataPart('image/jpeg', reduzida),
    ]));
  }

  /// Analisa a descrição digitada (ex.: Avistei sem foto).
  static Future<SugestaoIA> analisarDescricao(String descricao) {
    return _gerar(Content.text(
        'Extraia os dados do pet a partir desta descrição: "$descricao"'));
  }

  static Future<SugestaoIA> _gerar(Content conteudo) async {
    final GenerateContentResponse resposta;
    try {
      resposta = await _modelo.generateContent([conteudo]).timeout(_timeout);
    } catch (e) {
      debugPrint('AIService: falha ao gerar: $e');
      throw IAException(mensagemDeErro(e));
    }

    final sugestao = SugestaoIA.converter(resposta.text);
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

  /// Mensagem para o usuário conforme o erro da chamada à IA. Função pura.
  /// (O pacote só exporta a classe base FirebaseAIException; o tipo do erro
  /// — cota, API desativada — é reconhecido pela mensagem.)
  static String mensagemDeErro(Object erro) {
    if (erro is TimeoutException) {
      return 'A IA demorou para responder. Confira a internet e tente de novo.';
    }
    if (erro is FirebaseAIException) {
      final msg = erro.message.toLowerCase();
      if (msg.contains('quota') ||
          msg.contains('exhausted') ||
          msg.contains('rate limit')) {
        return 'O limite de uso da IA foi atingido. Tente mais tarde ou preencha manualmente.';
      }
      if (msg.contains('firebasevertexai') ||
          msg.contains('firebaseml') ||
          msg.contains('not been used') ||
          msg.contains('to be enabled') ||
          msg.contains('is disabled')) {
        return 'A IA ainda não foi ativada neste projeto. Preencha manualmente.';
      }
      return 'A IA não conseguiu responder agora. Tente de novo ou preencha manualmente.';
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

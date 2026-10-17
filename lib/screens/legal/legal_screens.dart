import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

/// Termos de Uso e Política de Privacidade (LGPD), em linguagem simples.
/// Textos de um protótipo acadêmico (TCC) — revisar antes de uso real.

class TermosScreen extends StatelessWidget {
  const TermosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DocumentoLegal(
      titulo: 'Termos de Uso',
      secoes: [
        ('O que é o PetPerdido',
            'Um aplicativo comunitário, feito como Trabalho de Conclusão de Curso, '
                'para ajudar a encontrar pets perdidos, com foco inicial em Itapetininga-SP. '
                'Você pode publicar que perdeu, achou ou avistou um animal, ver os posts '
                'no mapa e no feed, registrar avistamentos e conversar com quem publicou.'),
        ('Quem pode usar',
            'Pessoas com 16 anos ou mais, com cadastro e CPF válido. O CPF serve para '
                'dificultar golpes e contas falsas; ele nunca aparece para outros usuários.'),
        ('O que você se compromete a fazer',
            '• Publicar só informações verdadeiras sobre animais.\n'
                '• Não usar o app para vender animais, aplicar golpes ou pedir dinheiro.\n'
                '• Tratar as outras pessoas com respeito no chat (há filtro de palavrões).\n'
                '• Combinar entregas em locais públicos e não enviar documentos pelo chat.'),
        ('Pontos e recompensas',
            'Os pontos reconhecem quem ajuda. As recompensas exibidas são exemplos de '
                'parcerias (uma expansão futura do projeto) e não têm valor comercial.'),
        ('Moderação',
            'Posts e mensagens que desrespeitem estes termos podem ser removidos, e a '
                'conta pode ser encerrada.'),
        ('Limites do serviço',
            'O PetPerdido aproxima pessoas, mas não garante que um pet será encontrado '
                'nem se responsabiliza pelos encontros combinados entre usuários.'),
      ],
    );
  }
}

class PrivacidadeScreen extends StatelessWidget {
  const PrivacidadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DocumentoLegal(
      titulo: 'Política de Privacidade',
      secoes: [
        ('Quais dados coletamos',
            '• Nome, e-mail e senha (a senha fica só no Firebase Authentication).\n'
                '• CPF e data de nascimento, para validar o cadastro e a idade mínima.\n'
                '• Localização aproximada (cerca de 100 m): do post, do avistamento e, se '
                'você ativar os alertas, a última posição conhecida ao abrir o app.\n'
                '• Fotos dos pets que você enviar.\n'
                '• Mensagens do chat, pontos e resgates.'),
        ('Para que usamos',
            '• Mostrar os posts no mapa e no feed.\n'
                '• Avisar quem está perto quando um pet some ou é encontrado.\n'
                '• Permitir a conversa entre quem perdeu e quem achou.\n'
                '• Sugerir espécie, porte e cor do pet a partir da foto (opcional).'),
        ('O que os outros usuários veem',
            'Seu nome, os posts e avistamentos que você publicar, só com o BAIRRO e uma '
                'área aproximada. Nunca o seu e-mail, CPF, data de nascimento ou localização '
                'exata. No chat, a outra pessoa vê apenas o seu nome.'),
        ('Serviços de terceiros',
            'Usamos o Firebase (Google) para cadastro, banco de dados, fotos, notificações '
                'e funções na nuvem. Quando você toca em "Preencher com IA", a foto ou a '
                'descrição é enviada à IA Gemini (Google) só para identificar o pet. Para '
                'achar o nome do bairro usamos o geocoding do aparelho ou o OpenStreetMap '
                '(Nominatim), enviando apenas coordenadas.'),
        ('Por quanto tempo guardamos',
            'Mensagens do chat são apagadas automaticamente 15 dias após o envio. Os '
                'demais dados ficam enquanto a sua conta existir.'),
        ('Seus direitos (LGPD)',
            'Você pode ver e corrigir seus dados nas Configurações, desligar os alertas '
                '(o que apaga a sua localização guardada) e excluir a conta a qualquer '
                'momento em "Excluir minha conta" — isso apaga seus posts, avistamentos, '
                'mensagens, pontos e o seu cadastro.'),
        ('Segurança',
            'Os dados são protegidos por regras de acesso no Firebase: cada pessoa só '
                'acessa o próprio cadastro, e só os participantes de uma conversa leem as '
                'mensagens.'),
      ],
    );
  }
}

class _DocumentoLegal extends StatelessWidget {
  final String titulo;
  final List<(String, String)> secoes;

  const _DocumentoLegal({required this.titulo, required this.secoes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Versão do protótipo de TCC — outubro de 2026.',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),
          for (final (subtitulo, texto) in secoes) ...[
            Text(subtitulo,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(texto, style: const TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

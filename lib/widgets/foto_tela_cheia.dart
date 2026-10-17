import 'package:flutter/material.dart';
import 'pet_image.dart';

/// Foto em tela cheia com zoom (pinça ou dois toques no celular, roda do
/// mouse na Web). Abre ao tocar na foto do detalhe do post.
class FotoTelaCheia extends StatelessWidget {
  final String url;

  const FotoTelaCheia({super.key, required this.url});

  static Future<void> abrir(BuildContext context, String url) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FotoTelaCheia(url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Fechar',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: PetImage(url: url, fit: BoxFit.contain, iconSize: 80),
        ),
      ),
    );
  }
}

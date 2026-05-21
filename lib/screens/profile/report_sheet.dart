import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class ReportSheet extends StatefulWidget {
  const ReportSheet({super.key});

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  int _currentStep = 1;
  String? _selectedTopic;
  final TextEditingController _descController = TextEditingController();
  bool _isSending = false;
  bool _attachedPhoto = false;

  final List<Map<String, dynamic>> _topics = [
    {
      'id': 'post_falso',
      'label': 'Postagem Falsa',
      'icon': Icons.report_gmailerrorred_outlined,
      'color': Colors.red,
    },
    {
      'id': 'maus_tratos',
      'label': 'Maus-tratos / Emergência',
      'icon': Icons.emergency_outlined,
      'color': Colors.orange,
    },
    {
      'id': 'erro_app',
      'label': 'Erro no Aplicativo',
      'icon': Icons.bug_report_outlined,
      'color': Colors.blue,
    },
    {
      'id': 'sugestao',
      'label': 'Sugerir Melhoria',
      'icon': Icons.lightbulb_outline,
      'color': Colors.green,
    },
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_currentStep == 1) _buildStep1() else if (_currentStep == 2) _buildStep2() else _buildSuccessState(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Suporte & Reportar',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
        const SizedBox(height: 6),
        const Text(
          'Como podemos ajudar você hoje? Selecione uma categoria para continuarmos.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
          ),
          itemCount: _topics.length,
          itemBuilder: (context, index) {
            final topic = _topics[index];
            final id = topic['id'] as String;
            final isSelected = _selectedTopic == id;
            final color = topic['color'] as Color;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedTopic = id);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.06) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey[200]!,
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      topic['icon'] as IconData,
                      color: isSelected ? color : Colors.grey[600],
                      size: 24,
                    ),
                    const Spacer(),
                    Text(
                      topic['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? color : AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            onPressed: _selectedTopic != null
                ? () => setState(() => _currentStep = 2)
                : null,
            child: const Text(
              'Avançar',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep2() {
    final label = _topics.firstWhere((t) => t['id'] == _selectedTopic)['label'] as String;
    final isDescriptionValid = _descController.text.trim().length >= 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.grey),
              onPressed: () => setState(() => _currentStep = 1),
            ),
            const Text(
              'Detalhes do Reporte',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Categoria selecionada: $label',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Descreva o problema com detalhes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descController,
          maxLines: 4,
          onChanged: (text) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Escreva pelo menos 10 caracteres para podermos analisar...',
            hintStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Anexo de captura
        GestureDetector(
          onTap: () {
            setState(() => _attachedPhoto = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Captura de tela anexada com sucesso!')),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _attachedPhoto ? Colors.teal : Colors.grey[300]!, style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_attachedPhoto ? Icons.check_circle : Icons.photo_library_outlined, color: _attachedPhoto ? Colors.teal : Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _attachedPhoto ? 'Captura de tela adicionada!' : 'Anexar imagem ou print (opcional)',
                  style: TextStyle(color: _attachedPhoto ? Colors.teal : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: isDescriptionValid && !_isSending
                ? () async {
                    setState(() => _isSending = true);
                    // Simular envio
                    await Future.delayed(const Duration(milliseconds: 1200));
                    if (mounted) {
                      setState(() {
                        _isSending = false;
                        _currentStep = 3;
                      });
                    }
                  }
                : null,
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Enviar Suporte',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal[50],
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: Colors.teal,
            size: 64,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Suporte enviado!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
        const SizedBox(height: 10),
        const Text(
          'Obrigado pelo seu relato. Nossa equipe analisará as informações confidenciais e responderá por e-mail dentro de 24 horas.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Ótimo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

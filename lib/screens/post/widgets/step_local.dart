import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_constants.dart';
import '../../../services/location_service.dart';
import '../post_draft.dart';
import '../post_options.dart';
import 'post_form_ui.dart';

/// Etapa 4 — Onde e quando: marcador no mapa, bairro e data/hora.
///
/// As coordenadas salvas são sempre as do marcador. O campo de bairro é
/// preenchido sozinho (endereço reverso), mas continua editável.
class StepLocal extends StatefulWidget {
  final PostDraft draft;
  final VoidCallback onChanged;

  const StepLocal({super.key, required this.draft, required this.onChanged});

  @override
  State<StepLocal> createState() => _StepLocalState();
}

class _StepLocalState extends State<StepLocal> {
  static const _centroPadrao =
      LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
  static const _msgSemBairro = 'Informe o bairro para os outros acharem o pet';

  GoogleMapController? _mapa;

  /// Debounce do endereço reverso ao mover o marcador (1 s).
  Timer? _debounce;

  /// Cada consulta de reverso ganha um número; respostas antigas são ignoradas.
  int _consulta = 0;

  bool _buscandoBairro = false;
  bool _localizando = false;
  bool _buscandoNoMapa = false;

  /// O reverso não achou o bairro: o campo fica vazio, com aviso.
  bool _semBairro = false;

  /// Aviso desta etapa (GPS negado, endereço não encontrado...).
  String? _aviso;
  String? _avisoData;

  PostDraft get _d => widget.draft;

  @override
  void dispose() {
    _debounce?.cancel();
    _mapa?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Marcador e endereço
  // ---------------------------------------------------------------------------

  /// Coloca o marcador em [ponto]. Por padrão busca o bairro depois de 1 s
  /// (debounce: arrastar várias vezes gera uma única consulta).
  void _marcar(LatLng ponto,
      {bool moverMapa = false,
      bool buscarBairro = true,
      Duration atraso = const Duration(seconds: 1)}) {
    _d.position = (lat: ponto.latitude, lng: ponto.longitude);
    if (moverMapa) _mapa?.animateCamera(CameraUpdate.newLatLngZoom(ponto, 16));

    _debounce?.cancel();
    if (buscarBairro) {
      _consulta++;
      _debounce = Timer(atraso, _buscarBairro);
    }
    setState(() {
      _aviso = null;
      _buscandoBairro = buscarBairro;
    });
    widget.onChanged();
  }

  Future<void> _buscarBairro() async {
    final pos = _d.position;
    if (pos == null) return;
    final consulta = _consulta;
    final bairro = await LocationService.bairroDe(pos.lat, pos.lng);
    if (!mounted || consulta != _consulta) return; // resposta antiga

    // Sem resultado: campo vazio e editável, com aviso (nunca texto genérico).
    _d.addressController.text = bairro ?? '';
    setState(() {
      _buscandoBairro = false;
      _semBairro = bairro == null;
    });
    widget.onChanged();
  }

  /// Digitar no campo cancela um reverso pendente, para não apagar o texto.
  void _editouBairro(String _) {
    _debounce?.cancel();
    _consulta++;
    setState(() {
      _buscandoBairro = false;
      _semBairro = false;
    });
    widget.onChanged();
  }

  Future<void> _usarLocalizacaoAtual() async {
    setState(() {
      _localizando = true;
      _aviso = null;
    });
    try {
      final pos = await LocationService.posicaoAtual();
      if (!mounted) return;
      _marcar(LatLng(pos.lat, pos.lng), moverMapa: true, atraso: Duration.zero);
    } on LocationException catch (e) {
      if (mounted) setState(() => _aviso = e.message);
    } finally {
      if (mounted) setState(() => _localizando = false);
    }
  }

  /// "Buscar no mapa": converte o texto em coordenadas e move o marcador,
  /// mantendo o texto digitado.
  Future<void> _buscarNoMapa() async {
    final texto = _d.addressController.text.trim();
    if (texto.isEmpty) {
      setState(() => _aviso = 'Digite o bairro para buscar no mapa.');
      return;
    }
    FocusScope.of(context).unfocus();
    _debounce?.cancel();
    _consulta++;
    setState(() {
      _buscandoNoMapa = true;
      _buscandoBairro = false;
      _aviso = null;
    });
    final pos = await LocationService.coordenadasDe(texto);
    if (!mounted) return;
    setState(() => _buscandoNoMapa = false);
    if (pos == null) {
      setState(() => _aviso =
          'Não encontramos esse endereço. Toque no mapa para marcar o ponto.');
      return;
    }
    _marcar(LatLng(pos.lat, pos.lng), moverMapa: true, buscarBairro: false);
  }

  // ---------------------------------------------------------------------------
  // Data e hora
  // ---------------------------------------------------------------------------

  void _escolherAtalho(QuandoAconteceu q) {
    setState(() => _avisoData = null);
    _d.quando = q;
    widget.onChanged();
  }

  Future<void> _escolherDataHora() async {
    final agora = DateTime.now();
    final atual = _d.eventAt(agora);
    final data = await showDatePicker(
      context: context,
      initialDate: atual,
      firstDate: agora.subtract(const Duration(days: 365)),
      lastDate: agora,
    );
    if (data == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(atual),
    );
    if (hora == null || !mounted) return;

    final escolhida =
        DateTime(data.year, data.month, data.day, hora.hour, hora.minute);
    if (escolhida.isAfter(DateTime.now())) {
      setState(() => _avisoData = 'A data e a hora não podem ser no futuro.');
      return;
    }
    setState(() => _avisoData = null);
    _d
      ..quando = QuandoAconteceu.escolhido
      ..dataEscolhida = escolhida;
    widget.onChanged();
  }

  // ---------------------------------------------------------------------------
  // Tela
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepTitulo(
          titulo: _d.tituloLocal,
          subtitulo: 'Toque no mapa ou arraste o marcador até o ponto exato.',
        ),
        _mapaComMarcador(),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.shield_outlined,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Mostramos só o bairro e uma área aproximada (cerca de 100 m) '
                'para outros usuários.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _localizando ? null : _usarLocalizacaoAtual,
          icon: _localizando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location, size: 18),
          label: Text(_localizando
              ? 'Obtendo localização...'
              : 'Usar minha localização atual'),
        ),
        const SizedBox(height: 24),
        const RotuloSecao('Bairro'),
        TextField(
          controller: _d.addressController,
          onChanged: _editouBairro,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Ex.: Centro, Itapetininga',
            prefixIcon: const Icon(Icons.location_on_outlined,
                color: AppColors.primary, size: 20),
            suffixIcon: _buscandoBairro
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            errorText: _semBairro ? _msgSemBairro : null,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _buscandoNoMapa ? null : _buscarNoMapa,
            icon: _buscandoNoMapa
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.travel_explore, size: 18),
            label: const Text('Buscar no mapa'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ),
        if (_aviso != null) ...[
          const SizedBox(height: 8),
          AvisoErro(_aviso!),
        ],
        const SizedBox(height: 24),
        RotuloSecao(_d.tituloQuando),
        _atalhosData(),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.event_outlined,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              formatarDataHora(_d.eventAt(DateTime.now())),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        if (_avisoData != null) ...[
          const SizedBox(height: 8),
          AvisoErro(_avisoData!),
        ],
      ],
    );
  }

  Widget _mapaComMarcador() {
    final pos = _d.position;
    final ponto = pos == null ? null : LatLng(pos.lat, pos.lng);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: ponto ?? _centroPadrao,
                zoom: ponto == null ? 13.5 : 16,
              ),
              onMapCreated: (c) => _mapa = c,
              onTap: _marcar,
              markers: {
                if (ponto != null)
                  Marker(
                    markerId: const MarkerId('local-do-pet'),
                    position: ponto,
                    draggable: true,
                    onDragEnd: _marcar,
                  ),
              },
              // Dentro de uma tela com rolagem, o mapa fica com os gestos.
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer()),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
            ),
            if (ponto == null)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: IgnorePointer(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app_outlined,
                            size: 16, color: AppColors.primary),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Toque no mapa para marcar o ponto',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _atalhosData() {
    final agora = DateTime.now();
    final opcoes = [
      (QuandoAconteceu.agora, 'Agora'),
      (QuandoAconteceu.hojeDeManha, 'Hoje de manhã'),
      (QuandoAconteceu.ontem, 'Ontem'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (q, rotulo) in opcoes)
          _chip(
            rotulo,
            selecionado: _d.quando == q,
            // "Hoje de manhã" só aparece habilitado depois das 9h.
            onTap: PostDraft.dataDoAtalho(q, agora) == null
                ? null
                : () => _escolherAtalho(q),
          ),
        _chip(
          _d.quando == QuandoAconteceu.escolhido ? 'Outra data' : 'Escolher',
          icone: Icons.edit_calendar_outlined,
          selecionado: _d.quando == QuandoAconteceu.escolhido,
          onTap: _escolherDataHora,
        ),
      ],
    );
  }

  Widget _chip(String rotulo,
      {required bool selecionado, VoidCallback? onTap, IconData? icone}) {
    return ChoiceChip(
      avatar: icone == null
          ? null
          : Icon(icone,
              size: 16,
              color: selecionado ? Colors.white : AppColors.textSecondary),
      label: Text(rotulo),
      selected: selecionado,
      onSelected: onTap == null ? null : (_) => onTap(),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selecionado ? Colors.white : AppColors.onSurface,
      ),
    );
  }
}

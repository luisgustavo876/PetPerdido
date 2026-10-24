import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show Locale;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';

/// Erro de localização com mensagem pronta para mostrar ao usuário.
class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}

/// GPS (geolocator) e conversão endereço <-> coordenadas.
///
/// A conversão usa o geocoding nativo do aparelho e, quando ele não funciona
/// (sempre na Web), o Nominatim do OpenStreetMap.
class LocationService {
  static final _geocoding = Geocoding(locale: const Locale('pt', 'BR'));

  static const _nominatimHost = 'nominatim.openstreetmap.org';
  static const _nominatimTimeout = Duration(seconds: 8);

  /// Política do Nominatim: no máximo 1 requisição por segundo.
  static DateTime _proximaChamadaNominatim = DateTime(2000);

  /// Arredonda uma coordenada para [casas] casas decimais
  /// (padrão: [AppConstants.coordDecimals], ≈ 100 m). Função pura.
  static double arredondar(double valor,
      {int casas = AppConstants.coordDecimals}) {
    final fator = math.pow(10, casas);
    return (valor * fator).round() / fator;
  }

  /// Posição atual do aparelho. Pede permissão se precisar.
  /// Lança [LocationException] com o motivo se não conseguir — inclusive em
  /// falhas inesperadas do plugin (nunca deixa escapar outro tipo de erro).
  static Future<({double lat, double lng})> posicaoAtual() async {
    try {
      return await _posicaoAtual();
    } on LocationException {
      rethrow;
    } catch (e) {
      debugPrint('LocationService: falha inesperada na localização: $e');
      throw const LocationException(
          'Não foi possível usar sua localização. Toque no mapa para marcar o ponto.');
    }
  }

  static Future<({double lat, double lng})> _posicaoAtual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException('Ative a localização (GPS) do aparelho.');
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied) {
      throw const LocationException('Permissão de localização negada.');
    }
    if (permissao == LocationPermission.deniedForever) {
      throw LocationException(kIsWeb
          ? 'Localização bloqueada no navegador. Libere no cadeado ao lado do '
              'endereço do site e tente de novo.'
          : 'Permissão de localização bloqueada. Libere nas configurações do aparelho.');
    }

    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return (lat: p.latitude, lng: p.longitude);
    } catch (_) {
      throw const LocationException(
          'Não foi possível obter sua localização. Tente novamente.');
    }
  }

  /// Posição atual SEM pedir permissão: retorna null se o usuário ainda não
  /// autorizou (ou se não for possível obter). Usada para a câmera inicial.
  static Future<({double lat, double lng})?> posicaoSemPedir() async {
    try {
      final permissao = await Geolocator.checkPermission();
      if (permissao != LocationPermission.always &&
          permissao != LocationPermission.whileInUse) {
        return null;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (lat: p.latitude, lng: p.longitude);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Endereço de uma coordenada (reverso)
  // ---------------------------------------------------------------------------

  /// "Bairro, Cidade" de uma coordenada, ou null se não encontrar.
  /// Fora da Web tenta o geocoding nativo e, se falhar, o Nominatim.
  static Future<String?> bairroDe(double lat, double lng) async {
    if (!kIsWeb) {
      final nativo = await _bairroNativo(lat, lng);
      if (nativo != null) return nativo;
    }
    return _bairroNominatim(lat, lng);
  }

  static Future<String?> _bairroNativo(double lat, double lng) async {
    try {
      final lugares = await _geocoding.placemarkFromCoordinates(lat, lng);
      if (lugares.isEmpty) return null;
      final p = lugares.first;
      return formatarBairroCidade(
        p.subLocality ?? p.thoroughfare,
        p.locality ?? p.subAdministrativeArea,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _bairroNominatim(double lat, double lng) async {
    final json = await _getNominatim('/reverse', {
      'format': 'jsonv2',
      'lat': '$lat',
      'lon': '$lng',
      'zoom': '16',
      'addressdetails': '1',
      'accept-language': 'pt-BR',
    });
    return json is Map<String, dynamic> ? textoDoNominatim(json) : null;
  }

  // ---------------------------------------------------------------------------
  // Coordenadas de um endereço (busca)
  // ---------------------------------------------------------------------------

  /// Coordenadas de um endereço digitado, completando com a cidade padrão.
  /// Fora da Web tenta o geocoding nativo e, se falhar, o Nominatim.
  /// Retorna null se não encontrar.
  static Future<({double lat, double lng})?> coordenadasDe(
      String endereco) async {
    final consulta = '$endereco, ${AppConstants.defaultCity}';
    if (!kIsWeb) {
      final nativo = await _coordenadasNativo(consulta);
      if (nativo != null) return nativo;
    }
    final json = await _getNominatim('/search', {
      'format': 'jsonv2',
      'q': consulta,
      'limit': '1',
      'countrycodes': 'br',
      'accept-language': 'pt-BR',
    });
    return coordenadasDoNominatim(json);
  }

  static Future<({double lat, double lng})?> _coordenadasNativo(
      String consulta) async {
    try {
      final locais = await _geocoding.locationFromAddress(consulta);
      if (locais.isEmpty) return null;
      return (lat: locais.first.latitude, lng: locais.first.longitude);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Nominatim (OpenStreetMap)
  // ---------------------------------------------------------------------------

  /// GET no Nominatim respeitando o limite de 1 requisição por segundo.
  /// Retorna o JSON decodificado ou null em qualquer erro (nunca lança).
  static Future<Object?> _getNominatim(
      String caminho, Map<String, String> parametros) async {
    try {
      await _aguardarVezNominatim();
      final resposta = await http
          .get(
            Uri.https(_nominatimHost, caminho, parametros),
            // O navegador não deixa definir User-Agent; na Web ele manda o
            // Referer, que também atende a política do Nominatim.
            headers: kIsWeb ? null : const {'User-Agent': 'PetPerdido-TCC/1.0'},
          )
          .timeout(_nominatimTimeout);
      if (resposta.statusCode != 200) return null;
      return jsonDecode(utf8.decode(resposta.bodyBytes));
    } catch (e) {
      debugPrint('LocationService: Nominatim falhou ($caminho): $e');
      return null;
    }
  }

  /// Reserva o próximo horário livre (1 s depois do anterior) e espera por
  /// ele. A reserva é feita antes de esperar, então chamadas simultâneas
  /// ficam em fila em vez de saírem juntas.
  static Future<void> _aguardarVezNominatim() async {
    final agora = DateTime.now();
    final inicio = _proximaChamadaNominatim.isAfter(agora)
        ? _proximaChamadaNominatim
        : agora;
    _proximaChamadaNominatim = inicio.add(const Duration(seconds: 1));
    final espera = inicio.difference(agora);
    if (espera > Duration.zero) await Future.delayed(espera);
  }

  // ---------------------------------------------------------------------------
  // Funções puras (testáveis)
  // ---------------------------------------------------------------------------

  /// Junta bairro e cidade em "Bairro, Cidade", ignorando partes vazias
  /// e repetidas. Retorna null se não houver nenhuma das duas.
  static String? formatarBairroCidade(String? bairro, String? cidade) {
    final partes = <String>[];
    for (final parte in [bairro, cidade]) {
      final texto = parte?.trim() ?? '';
      if (texto.isNotEmpty && !partes.contains(texto)) partes.add(texto);
    }
    return partes.isEmpty ? null : partes.join(', ');
  }

  /// Extrai "Bairro, Cidade" da resposta do /reverse do Nominatim.
  /// Nunca usa número da casa — só bairro (ou, sem bairro, o nome da rua).
  static String? textoDoNominatim(Map<String, dynamic> json) {
    final endereco = json['address'];
    if (endereco is! Map) return null;
    String? campo(String nome) {
      final valor = endereco[nome];
      return valor is String && valor.trim().isNotEmpty ? valor : null;
    }

    final bairro = campo('suburb') ??
        campo('neighbourhood') ??
        campo('city_district') ??
        campo('quarter') ??
        campo('road');
    final cidade = campo('city') ?? campo('town') ?? campo('village');
    return formatarBairroCidade(bairro, cidade);
  }

  /// Coordenadas do primeiro resultado do /search do Nominatim, ou null.
  static ({double lat, double lng})? coordenadasDoNominatim(Object? json) {
    if (json is! List || json.isEmpty || json.first is! Map) return null;
    final primeiro = json.first as Map;
    final lat = double.tryParse('${primeiro['lat']}');
    final lng = double.tryParse('${primeiro['lon']}');
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  }
}

import 'dart:math' as math;
import 'dart:ui' show Locale;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../core/app_constants.dart';

/// Erro de localização com mensagem pronta para mostrar ao usuário.
class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}

/// GPS (geolocator) e conversão endereço <-> coordenadas (geocoding).
class LocationService {
  static final _geocoding = Geocoding(locale: const Locale('pt', 'BR'));

  /// Arredonda uma coordenada para [casas] casas decimais
  /// (padrão: [AppConstants.coordDecimals], ≈ 100 m). Função pura.
  static double arredondar(double valor,
      {int casas = AppConstants.coordDecimals}) {
    final fator = math.pow(10, casas);
    return (valor * fator).round() / fator;
  }

  /// Posição atual do aparelho. Pede permissão se precisar.
  /// Lança [LocationException] com o motivo se não conseguir.
  static Future<({double lat, double lng})> posicaoAtual() async {
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
      throw const LocationException(
          'Permissão de localização bloqueada. Libere nas configurações do aparelho.');
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

  /// Bairro (ou rua, se não houver bairro) de uma coordenada.
  /// Retorna null se não conseguir — por exemplo na Web, onde o
  /// geocoding não funciona.
  static Future<String?> bairroDe(double lat, double lng) async {
    try {
      final lugares = await _geocoding.placemarkFromCoordinates(lat, lng);
      if (lugares.isEmpty) return null;
      final p = lugares.first;
      for (final parte in [p.subLocality, p.thoroughfare, p.locality]) {
        if (parte != null && parte.trim().isNotEmpty) return parte.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Coordenadas de um endereço digitado, completando com a cidade padrão.
  /// Retorna null se não encontrar (ou na Web, onde não funciona).
  static Future<({double lat, double lng})?> coordenadasDe(
      String endereco) async {
    try {
      final locais = await _geocoding
          .locationFromAddress('$endereco, ${AppConstants.defaultCity}');
      if (locais.isEmpty) return null;
      return (lat: locais.first.latitude, lng: locais.first.longitude);
    } catch (_) {
      return null;
    }
  }
}

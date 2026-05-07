/// Constantes globais do aplicativo.
class AppConstants {
  AppConstants._();

  static const String appName = 'PetPerdido';

  // Tipos de post (usados nos models e na UI)
  static const String postTypeLost = 'perdi';
  static const String postTypeFound = 'achei';
  static const String postTypeSighted = 'avistei';

  // Labels de exibição
  static const Map<String, String> postTypeLabels = {
    postTypeLost: 'Perdi meu Pet',
    postTypeFound: 'Achei um Pet',
    postTypeSighted: 'Avistei um Pet',
  };

  // Localização padrão (Itapetininga - SP)
  static const double defaultLat = -23.5897;
  static const double defaultLng = -48.0533;

  // Validações
  static const int minPasswordLength = 10;
  static const int cpfLength = 11;
}

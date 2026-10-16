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

  /// Complemento usado ao converter o endereço digitado em coordenadas.
  static const String defaultCity = 'Itapetininga, SP, Brasil';

  /// Casas decimais das coordenadas salvas nos posts (3 ≈ 100 m).
  /// Evita expor a localização exata de quem publica (LGPD).
  static const int coordDecimals = 3;

  // Aviso de posts semelhantes (Perdi x Achei/Avistei)
  static const int similarWindowDays = 7;
  static const double similarMaxKm = 3;

  // Validações (6 é o mínimo aceito pelo Firebase Auth)
  static const int minPasswordLength = 6;
  static const int cpfLength = 11;
  static const int minAge = 16;

  // Pontos com que todo usuário novo começa
  static const int initialPoints = 0;
}

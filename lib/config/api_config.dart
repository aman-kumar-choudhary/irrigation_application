class ApiConfig {
  // Mobile cannot use localhost for a backend running on your laptop.
  // Change this one IP when your backend machine/network changes; API and
  // GeoServer will stay aligned for both Android and the web-style map layers.
  static const String backendHost = '192.168.17.28';

  static const String baseUrl = 'http://$backendHost:8000';
  static const String geoserverUrl = 'http://$backendHost:8080/geoserver';
  static const String workspace = 'irrigation';

  // Open-Meteo (direct from mobile)
  static const String openMeteoUrl = 'https://api.open-meteo.com/v1';
  static const String openMeteoArchiveUrl =
      'https://archive-api.open-meteo.com/v1';
}

class ApiConfig {
  // Android emulator can reach the host machine at 10.0.2.2. The Docker
  // compose stack exposes backend and GeoServer through nginx on port 80.
  //
  // Physical phone on the same Wi-Fi:
  // flutter run --dart-define=BACKEND_HOST=192.168.x.x
  //
  // Direct backend/geoserver without nginx:
  // flutter run --dart-define=API_PORT=8000 --dart-define=GEOSERVER_PORT=8080 \
  //   --dart-define=GEOSERVER_BASE_PATH=/geoserver
  static const String backendHost = String.fromEnvironment(
    'BACKEND_HOST',
    defaultValue: '10.0.2.2',
  );
  static const String backendScheme = String.fromEnvironment(
    'BACKEND_SCHEME',
    defaultValue: 'http',
  );
  static const String apiPort = String.fromEnvironment(
    'API_PORT',
    defaultValue: '80',
  );
  static const String geoserverPort = String.fromEnvironment(
    'GEOSERVER_PORT',
    defaultValue: '80',
  );
  static const String apiBasePath = String.fromEnvironment(
    'API_BASE_PATH',
    defaultValue: '',
  );
  static const String geoserverBasePath = String.fromEnvironment(
    'GEOSERVER_BASE_PATH',
    defaultValue: '/geoserver',
  );
  static const Duration requestTimeout = Duration(
    seconds: int.fromEnvironment('API_TIMEOUT_SECONDS', defaultValue: 25),
  );

  static final String baseUrl = _joinUrl(_origin(apiPort), apiBasePath);
  static final String geoserverUrl =
      _joinUrl(_origin(geoserverPort), geoserverBasePath);
  static const String workspace = 'irrigation';

  // Open-Meteo (direct from mobile)
  static const String openMeteoUrl = 'https://api.open-meteo.com/v1';
  static const String openMeteoArchiveUrl =
      'https://archive-api.open-meteo.com/v1';

  static String _origin(String port) {
    final cleanPort = port.trim();
    return cleanPort.isEmpty
        ? '$backendScheme://$backendHost'
        : '$backendScheme://$backendHost:$cleanPort';
  }

  static String _joinUrl(String origin, String path) {
    final cleanPath = path.trim();
    if (cleanPath.isEmpty || cleanPath == '/') return origin;
    return '$origin/${cleanPath.replaceFirst(RegExp(r'^/+'), '')}';
  }
}

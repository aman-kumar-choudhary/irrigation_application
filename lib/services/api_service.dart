import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/weather_model.dart';
import '../models/point_data_model.dart';
import '../models/history_model.dart';
import '../models/chart_data_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _client = http.Client();

  Future<http.Response> _get(Uri url, {Map<String, String>? headers}) async {
    try {
      return await _client
          .get(url, headers: headers)
          .timeout(ApiConfig.requestTimeout);
    } on TimeoutException {
      throw Exception(
        'Connection timed out for ${url.host}:${url.port}. Check Docker port mapping and BACKEND_HOST.',
      );
    }
  }

  Future<http.Response> _post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      return await _client
          .post(url, headers: headers, body: body)
          .timeout(ApiConfig.requestTimeout);
    } on TimeoutException {
      throw Exception(
        'Connection timed out for ${url.host}:${url.port}. Check Docker port mapping and BACKEND_HOST.',
      );
    }
  }

  // ─── Weather (Open-Meteo) ───────────────────────────────────────────
  Future<WeatherData> fetchWeather(double lat, double lon,
      {int days = 7}) async {
    final url = Uri.parse(
      '${ApiConfig.openMeteoUrl}/forecast?latitude=$lat&longitude=$lon'
      '&daily=weathercode,temperature_2m_max,temperature_2m_min,precipitation_sum,windspeed_10m_max,uv_index_max'
      '&timezone=auto&forecast_days=$days',
    );

    final res = await _get(url);
    if (res.statusCode != 200) throw Exception('Weather fetch failed');

    return WeatherData.fromJson(
      jsonDecode(res.body),
      DateTime.now().toIso8601String(),
    );
  }

  Future<WeatherData> fetchHistoricalWeather(
      double lat, double lon, String date) async {
    // Fetch historical + forecast combined
    final historyUrl = Uri.parse(
      '${ApiConfig.openMeteoArchiveUrl}/archive?latitude=$lat&longitude=$lon'
      '&start_date=$date&end_date=$date'
      '&daily=weathercode,temperature_2m_max,temperature_2m_min,precipitation_sum,windspeed_10m_max'
      '&timezone=auto',
    );

    final forecastUrl = Uri.parse(
      '${ApiConfig.openMeteoUrl}/forecast?latitude=$lat&longitude=$lon'
      '&daily=weathercode,temperature_2m_max,temperature_2m_min,precipitation_sum,windspeed_10m_max,uv_index_max'
      '&timezone=auto&forecast_days=7',
    );

    final responses = await Future.wait([
      _get(historyUrl),
      _get(forecastUrl),
    ]);

    if (responses[0].statusCode != 200 || responses[1].statusCode != 200) {
      throw Exception('Historical weather fetch failed');
    }

    final history = jsonDecode(responses[0].body);
    final forecast = jsonDecode(responses[1].body);

    // Combine
    final hDaily = history['daily'] as Map<String, dynamic>;
    final fDaily = forecast['daily'] as Map<String, dynamic>;

    final combined = {
      'daily': {
        'time': [...hDaily['time'], ...fDaily['time']],
        'weathercode': [...hDaily['weathercode'], ...fDaily['weathercode']],
        'temperature_2m_max': [
          ...hDaily['temperature_2m_max'],
          ...fDaily['temperature_2m_max']
        ],
        'temperature_2m_min': [
          ...hDaily['temperature_2m_min'],
          ...fDaily['temperature_2m_min']
        ],
        'precipitation_sum': [
          ...(hDaily['precipitation_sum'] ?? []),
          ...(fDaily['precipitation_sum'] ?? [])
        ],
        'windspeed_10m_max': [
          ...(hDaily['windspeed_10m_max'] ?? []),
          ...(fDaily['windspeed_10m_max'] ?? [])
        ],
        'uv_index_max': [null, ...(fDaily['uv_index_max'] ?? [])],
      }
    };

    return WeatherData.fromJson(combined, DateTime.now().toIso8601String());
  }

  // ─── Backend API ────────────────────────────────────────────────────
  Future<List<AvailableDate>> fetchHistory() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/history');
    final res = await _get(url);

    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res, 'History fetch failed'));
    }

    final data = jsonDecode(res.body);
    final slots = data['slots'] as List<dynamic>? ?? [];

    return slots
        .whereType<Map<String, dynamic>>()
        .map(AvailableDate.fromJson)
        .toList();
  }

  Future<PointData> fetchPointData(double lat, double lon, String slot) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/point?lat=$lat&lon=$lon&slot=$slot',
    );
    final res = await _get(url);

    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res, 'Point data fetch failed'));
    }

    return PointData.fromJson(jsonDecode(res.body));
  }

  Future<Map<String, dynamic>> fetchBoundary() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/boundary');
    final res = await _get(url);

    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res, 'Boundary fetch failed'));
    }

    return jsonDecode(res.body);
  }

  Future<ChartData> fetchChartData(String layer, String mode) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/graph/seasonal-chart?layer=$layer&mode=$mode',
    );
    final res = await _get(url);

    if (res.statusCode != 200) {
      final detail = jsonDecode(res.body);
      throw Exception(detail['detail'] ?? 'Chart fetch failed');
    }

    return ChartData.fromJson(jsonDecode(res.body));
  }

  Future<Map<String, dynamic>> sendChat(
      String query, List<Map<String, String>> history) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/chat');
    final res = await _post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': query, 'history': history}),
    );

    if (res.statusCode != 200) throw Exception('Chat request failed');

    return jsonDecode(res.body);
  }

  // ─── Reverse Geocoding ──────────────────────────────────────────────
  Future<String> reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=10&addressdetails=1',
      );
      final res = await _get(url, headers: {'Accept-Language': 'en'});

      if (res.statusCode != 200)
        return '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';

      final data = jsonDecode(res.body);
      final addr = data['address'] as Map<String, dynamic>? ?? {};

      return addr['city'] ??
          addr['town'] ??
          addr['village'] ??
          addr['suburb'] ??
          addr['district'] ??
          addr['county'] ??
          'Selected Location';
    } catch (e) {
      return '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';
    }
  }

  String _errorMessage(http.Response response, String fallback) {
    try {
      final data = jsonDecode(response.body);
      final detail = data is Map<String, dynamic> ? data['detail'] : null;
      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString();
      }
    } catch (_) {
      // Keep the original fallback if the backend did not return JSON.
    }
    return '$fallback (${response.statusCode})';
  }
}

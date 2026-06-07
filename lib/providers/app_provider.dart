import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/weather_model.dart';
import '../models/point_data_model.dart';
import '../models/history_model.dart';
import '../services/api_service.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // Theme
  bool isDark = true;

  // Navigation
  int currentIndex = 0;

  // Layers
  final Map<String, bool> layers = {
    'savi': false,
    'kc': false,
    'etc': false,
    'cwr': false,
    'iwr': false,
  };
  double opacity = 1.0;
  String mapStyle = 'street';
  String? forecastWindow;

  // Weather
  WeatherData? weatherData;
  bool weatherLoading = false;
  String userLocationName = 'Udham Singh Nagar';
  double weatherLat = 28.98;
  double weatherLon = 79.40;
  int selectedWeatherIndex = 0;

  // Calendar / History
  List<AvailableDate> availableDates = [];
  bool historyLoading = false;
  String currentSlot = 'today';
  DateTime? selectedDate;

  // Map
  LatLng? selectedLocation;
  PointData? pointData;
  bool pointLoading = false;

  // Chart
  bool chartVisible = false;

  // Chat
  bool chatOpen = false;

  void toggleTheme() {
    isDark = !isDark;
    notifyListeners();
  }

  void setIndex(int idx) {
    currentIndex = idx;
    notifyListeners();
  }

  void toggleLayer(String key) {
    layers[key] = !(layers[key] ?? false);
    notifyListeners();
  }

  void setOpacity(double val) {
    opacity = val;
    notifyListeners();
  }

  void setMapStyle(String style) {
    mapStyle = style;
    notifyListeners();
  }

  void setForecastWindow(String? window) {
    forecastWindow = window;
    notifyListeners();
  }

  void selectWeatherEntry(int index) {
    selectedWeatherIndex = index;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    historyLoading = true;
    notifyListeners();

    try {
      availableDates = await _api.fetchHistory();
      if (availableDates.isNotEmpty && selectedDate == null) {
        selectedDate = DateTime.parse(availableDates.first.date);
        currentSlot = availableDates.first.slot;
      }
    } catch (e) {
      debugPrint('History error: $e');
    } finally {
      historyLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWeather({double? lat, double? lon}) async {
    weatherLoading = true;
    notifyListeners();

    try {
      if (lat == null || lon == null) {
        // Try to get device location
        try {
          // Note: Requires location permission
          // For now, use defaults
          lat = weatherLat;
          lon = weatherLon;
        } catch (e) {
          lat = weatherLat;
          lon = weatherLon;
        }
      }

      weatherLat = lat;
      weatherLon = lon;
      weatherData = await _api.fetchWeather(lat, lon);
      selectedWeatherIndex = 0;
    } catch (e) {
      debugPrint('Weather error: $e');
    } finally {
      weatherLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPointData(LatLng loc) async {
    pointLoading = true;
    selectedLocation = loc;
    pointData = null;
    notifyListeners();

    try {
      pointData =
          await _api.fetchPointData(loc.latitude, loc.longitude, currentSlot);
      userLocationName = await _api.reverseGeocode(loc.latitude, loc.longitude);
    } catch (e) {
      debugPrint('Point data error: $e');
      pointData = null;
    } finally {
      pointLoading = false;
      notifyListeners();
    }
  }

  void clearPointData() {
    selectedLocation = null;
    pointData = null;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    selectedDate = date;
    final iso = date.toIso8601String().split('T')[0];
    final match = availableDates.where((d) => d.date == iso).firstOrNull;
    currentSlot = match?.slot ?? 'today';
    notifyListeners();
  }

  void clearDate() {
    selectedDate = null;
    currentSlot = 'today';
    notifyListeners();
  }
}

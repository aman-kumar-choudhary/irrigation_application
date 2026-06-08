import 'dart:async';

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
  String mapStyle = 'satellite';
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
  String? historyError;
  String currentSlot = 'today';
  DateTime? selectedDate;

  // Map
  LatLng? selectedLocation;
  PointData? pointData;
  bool pointLoading = false;
  String? pointError;
  int _pointRequestId = 0;

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
    historyError = null;
    notifyListeners();

    try {
      availableDates = await _api.fetchHistory();
      if (availableDates.isNotEmpty && selectedDate == null) {
        selectedDate = DateTime.parse(availableDates.first.date);
        currentSlot = availableDates.first.slot;
      }
    } catch (e) {
      debugPrint('History error: $e');
      historyError = e.toString().replaceFirst('Exception: ', '');
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

  Future<void> fetchWeatherForDate(DateTime date) async {
    weatherLoading = true;
    notifyListeners();

    try {
      final today = DateTime.now();
      final selectedDay = DateTime(date.year, date.month, date.day);
      final todayDay = DateTime(today.year, today.month, today.day);
      if (selectedDay.isBefore(todayDay)) {
        final iso = selectedDay.toIso8601String().split('T')[0];
        weatherData =
            await _api.fetchHistoricalWeather(weatherLat, weatherLon, iso);
      } else {
        weatherData = await _api.fetchWeather(weatherLat, weatherLon);
      }
      selectedWeatherIndex = 0;
    } catch (e) {
      debugPrint('Dated weather error: $e');
    } finally {
      weatherLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPointData(LatLng loc) async {
    final requestId = ++_pointRequestId;
    pointLoading = true;
    selectedLocation = loc;
    pointData = null;
    pointError = null;
    notifyListeners();

    try {
      final data =
          await _api.fetchPointData(loc.latitude, loc.longitude, currentSlot);
      final locationName = await _api.reverseGeocode(data.lat, data.lon);
      if (requestId != _pointRequestId) return;
      pointData = data;
      userLocationName = locationName;
    } catch (e) {
      if (requestId != _pointRequestId) return;
      debugPrint('Point data error: $e');
      pointData = null;
      pointError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (requestId == _pointRequestId) {
        pointLoading = false;
        notifyListeners();
      }
    }
  }

  void clearPointData() {
    _pointRequestId++;
    selectedLocation = null;
    pointData = null;
    pointError = null;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    selectedDate = date;
    final iso = date.toIso8601String().split('T')[0];
    final match = availableDates.where((d) => d.date == iso).firstOrNull;
    currentSlot = match?.slot ?? 'today';
    notifyListeners();
    unawaited(fetchWeatherForDate(date));
    final loc = selectedLocation;
    if (loc != null) {
      unawaited(fetchPointData(loc));
    }
  }

  void clearDate() {
    selectedDate = null;
    currentSlot = 'today';
    notifyListeners();
    unawaited(fetchWeather());
    final loc = selectedLocation;
    if (loc != null) {
      unawaited(fetchPointData(loc));
    }
  }
}

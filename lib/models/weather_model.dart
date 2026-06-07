class WeatherData {
  final List<DailyWeather> daily;
  final String fetchedAt;

  WeatherData({required this.daily, required this.fetchedAt});

  factory WeatherData.fromJson(Map<String, dynamic> json, String fetchedAt) {
    final daily = json['daily'] as Map<String, dynamic>;
    final times = List<String>.from(daily['time']);
    
    return WeatherData(
      daily: List.generate(times.length, (i) {
        return DailyWeather(
          date: times[i],
          weatherCode: daily['weathercode'][i],
          tempMax: (daily['temperature_2m_max'][i] as num).toDouble(),
          tempMin: (daily['temperature_2m_min'][i] as num).toDouble(),
          precip: (daily['precipitation_sum']?[i] ?? 0).toDouble(),
          windSpeed: (daily['windspeed_10m_max']?[i] ?? 0).toDouble(),
          uvIndex: (daily['uv_index_max']?[i] ?? 0).toDouble(),
        );
      }),
      fetchedAt: fetchedAt,
    );
  }
}

class DailyWeather {
  final String date;
  final int weatherCode;
  final double tempMax;
  final double tempMin;
  final double precip;
  final double windSpeed;
  final double uvIndex;

  DailyWeather({
    required this.date,
    required this.weatherCode,
    required this.tempMax,
    required this.tempMin,
    required this.precip,
    required this.windSpeed,
    required this.uvIndex,
  });

  String get emoji {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '⛅';
    if (weatherCode <= 48) return '🌫️';
    if (weatherCode <= 55) return '🌧️';
    if (weatherCode <= 65) return '🌦️';
    if (weatherCode <= 75) return '❄️';
    if (weatherCode <= 82) return '🌦️';
    if (weatherCode <= 99) return '⛈️';
    return '🌤️';
  }

  String get description {
    const map = {
      0: 'Clear Sky', 1: 'Mainly Clear', 2: 'Partly Cloudy', 3: 'Overcast',
      45: 'Foggy', 48: 'Depositing Rime Fog', 51: 'Light Drizzle',
      53: 'Moderate Drizzle', 55: 'Dense Drizzle', 61: 'Slight Rain',
      63: 'Moderate Rain', 65: 'Heavy Rain', 71: 'Slight Snowfall',
      73: 'Moderate Snowfall', 75: 'Heavy Snowfall', 95: 'Thunderstorm',
      96: 'Thunderstorm + Hail', 99: 'Thunderstorm + Hail'
    };
    return map[weatherCode] ?? 'Cloudy';
  }
}
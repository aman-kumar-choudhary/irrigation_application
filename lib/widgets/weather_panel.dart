import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/weather_model.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';

class WeatherPanel extends StatelessWidget {
  final VoidCallback? onClose;

  const WeatherPanel({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final weather = provider.weatherData;
    final isDark = provider.isDark;

    if (provider.weatherLoading) {
      return _buildLoading(isDark);
    }

    if (weather == null || weather.daily.isEmpty) {
      return _buildError(provider, isDark);
    }

    final selected = weather.daily[provider.selectedWeatherIndex];

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xF50A1924), Color(0xF00E202D)],
              )
            : null,
        color: isDark ? null : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color:
                isDark ? Colors.white.withOpacity(0.14) : AppTheme.lightBorder,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Weather Forecast',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFEFFBFF)
                            : AppTheme.lightText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location, size: 20),
                    onPressed: () => provider.fetchWeather(),
                    color: AppTheme.brandTeal,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      if (onClose != null) {
                        onClose!();
                      } else {
                        Navigator.maybePop(context);
                      }
                    },
                    color: isDark
                        ? AppTheme.darkTextMuted
                        : AppTheme.lightTextMuted,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _weatherHeader(provider, selected, isDark),
              const SizedBox(height: 16),
              _metricGrid(selected, isDark),
              const SizedBox(height: 18),
              _forecastStrip(weather.daily, provider, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weatherHeader(
    AppProvider provider,
    DailyWeather selected,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppTheme.lightSurface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.10) : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Text(selected.emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.userLocationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextSoft : AppTheme.lightText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${provider.weatherLat.toStringAsFixed(4)}°N, ${provider.weatherLon.toStringAsFixed(4)}°E',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'JetBrains Mono',
                    color: isDark
                        ? AppTheme.darkTextMuted
                        : AppTheme.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  DateFormat('dd MMM yyyy')
                      .format(DateTime.parse(selected.date)),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.brandTeal : AppTheme.brandPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${selected.tempMax.round()}°C',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppTheme.lightText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricGrid(DailyWeather selected, bool isDark) {
    final metrics = [
      _WeatherMetric('🌡️', 'Temperature', '${selected.tempMax.round()}°C'),
      _WeatherMetric(
          '🌧️', 'Rainfall', '${selected.precip.toStringAsFixed(1)} mm'),
      _WeatherMetric(
          '💨', 'Wind Speed', '${selected.windSpeed.toStringAsFixed(1)} m/s'),
      _WeatherMetric('☀️', 'UV Index', selected.uvIndex.toStringAsFixed(1)),
      _WeatherMetric('🌡️', 'Min Temp', '${selected.tempMin.round()}°C'),
      _WeatherMetric('☁️', 'Condition', selected.description),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 310 ? 1 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: columns == 1 ? 3.8 : 1.28,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return _metricCard(metric, isDark);
          },
        );
      },
    );
  }

  Widget _metricCard(_WeatherMetric metric, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppTheme.lightSurface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(metric.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 7),
          Text(
            metric.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFF3B9FD9) : AppTheme.brandPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _forecastStrip(
    List<DailyWeather> days,
    AppProvider provider,
    bool isDark,
  ) {
    return SizedBox(
      height: 104,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = index == provider.selectedWeatherIndex;

          return GestureDetector(
            onTap: () => provider.selectWeatherEntry(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 72,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.brandPrimary.withOpacity(isDark ? 0.24 : 0.12)
                    : isDark
                        ? Colors.white.withOpacity(0.04)
                        : AppTheme.lightSurface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.brandPrimary
                      : isDark
                          ? Colors.white.withOpacity(0.08)
                          : AppTheme.lightBorder,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(DateTime.parse(day.date)),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.darkTextMuted
                          : AppTheme.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(day.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 5),
                  Text(
                    '${day.tempMax.round()}°',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.lightText,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102235) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppTheme.brandTeal),
      ),
    );
  }

  Widget _buildError(AppProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102235) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 48,
            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'Weather data unavailable',
            style: TextStyle(
              color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => provider.fetchWeather(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _WeatherMetric {
  final String icon;
  final String label;
  final String value;

  const _WeatherMetric(this.icon, this.label, this.value);
}

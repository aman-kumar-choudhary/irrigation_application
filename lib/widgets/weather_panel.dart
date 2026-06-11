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

  // Get today's weather only
  final today = weather.daily.first;

  return Container(
    width: 280, // Fixed compact width
    decoration: BoxDecoration(
      gradient: isDark
          ? const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xF50A1924), Color(0xF00E202D)],
            )
          : null,
      color: isDark ? null : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.14) : AppTheme.lightBorder,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.24),
          blurRadius: 30,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close button row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  if (onClose != null) {
                    onClose!();
                  }
                },
                color: isDark
                    ? AppTheme.darkTextMuted
                    : AppTheme.lightTextMuted,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          // Weather content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location name
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppTheme.brandTeal,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        provider.userLocationName.isNotEmpty
                            ? provider.userLocationName
                            : 'Current Location',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.darkTextSoft
                              : AppTheme.lightTextSoft,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Date
                Text(
                  DateFormat('dd MMM yyyy').format(DateTime.parse(today.date)),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppTheme.darkTextMuted
                        : AppTheme.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 8),
                // Main weather display - Large emoji and temp
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      today.emoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${today.tempMax.round()}°C',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppTheme.lightText,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          today.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.darkTextMuted
                                : AppTheme.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Quick metrics row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.04)
                        : AppTheme.lightSurface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _CompactMetric(
                        icon: '🌧️',
                        value: '${today.precip.toStringAsFixed(1)} mm',
                        label: 'Rain',
                        isDark: isDark,
                      ),
                      _CompactMetric(
                        icon: '💨',
                        value: '${today.windSpeed.toStringAsFixed(1)} m/s',
                        label: 'Wind',
                        isDark: isDark,
                      ),
                      _CompactMetric(
                        icon: '☀️',
                        value: today.uvIndex.toStringAsFixed(1),
                        label: 'UV',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Min temp row
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_downward, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Min ${today.tempMin.round()}°C',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppTheme.darkTextMuted
                              : AppTheme.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildLoading(bool isDark) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102235) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.brandTeal,
          ),
        ),
      ),
    );
  }

  Widget _buildError(AppProvider provider, bool isDark) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102235) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 32,
            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
          ),
          const SizedBox(height: 8),
          Text(
            'Weather unavailable',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 28,
            child: ElevatedButton(
              onPressed: () => provider.fetchWeather(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: AppTheme.brandTeal,
              ),
              child: const Text('Retry', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}

// Compact metric widget for the weather panel
class _CompactMetric extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final bool isDark;

  const _CompactMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.lightText,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
          ),
        ),
      ],
    );
  }
}
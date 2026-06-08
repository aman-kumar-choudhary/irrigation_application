import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/point_data_model.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class InfoPanelSheet extends StatelessWidget {
  final VoidCallback? onClose;
  final bool floating;

  const InfoPanelSheet({
    super.key,
    this.onClose,
    this.floating = false,
  });

  void _close(BuildContext context, AppProvider provider) {
    provider.clearPointData();
    if (onClose != null) {
      onClose!();
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final data = provider.pointData;
    final isDark = provider.isDark;

    if (data == null) {
      return Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF080C14).withOpacity(0.96)
              : Colors.white.withOpacity(0.96),
          borderRadius: floating
              ? BorderRadius.circular(24)
              : const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: provider.pointLoading
                  ? const CircularProgressIndicator.adaptive()
                  : Text(
                      provider.pointError ?? 'No pixel data available',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextSoft
                            : AppTheme.lightTextSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    final displayLayers = Constants.layerDefinitions;
    final displayDate = provider.selectedDate != null
        ? DateFormat('dd MMM yyyy').format(provider.selectedDate!)
        : data.acquisitionDate;
    final radius = floating
        ? BorderRadius.circular(24)
        : const BorderRadius.vertical(top: Radius.circular(24));

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF080C14).withOpacity(0.96)
            : Colors.white.withOpacity(0.96),
        borderRadius: radius,
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: isDark
                                ? AppTheme.brandTeal
                                : AppTheme.brandPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Selected Point',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.darkText
                                  : AppTheme.lightText,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => _close(context, provider),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Meta rows
                    _metaRow(
                      Icons.satellite_alt_outlined,
                      'Date',
                      displayDate,
                      isDark,
                    ),
                    _metaRow(
                      Icons.public_outlined,
                      'Location',
                      '${_formatCoord(data.lat, 'N', 'S')}, ${_formatCoord(data.lon, 'E', 'W')}',
                      isDark,
                    ),
                    if (data.pixelId != null)
                      _metaRow(
                        Icons.grid_on_outlined,
                        'Pixel',
                        data.pixelId!,
                        isDark,
                      ),
                    if (data.row != null && data.col != null)
                      _metaRow(
                        Icons.table_rows_outlined,
                        'Raster cell',
                        'Row ${data.row}, Col ${data.col}',
                        isDark,
                      ),

                    const SizedBox(height: 16),

                    // Values
                    ...displayLayers.map(
                      (layer) => _layerValues(layer, data, provider, isDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String label, String value, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? AppTheme.brandTeal : AppTheme.brandPrimary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _layerValues(
    Map<String, dynamic> layer,
    PointData pointData,
    AppProvider provider,
    bool isDark,
  ) {
    final key = layer['key'] as String;
    final value = pointData.values[key];
    final displayName = layer['name'] as String;
    final unit = layer['unit'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFB9CFDD) : AppTheme.lightTextSoft,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.035)
                : Colors.black.withOpacity(0.025),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _valueTile(
                label: 'Observed',
                value: value,
                layer: key,
                unit: unit,
                active: provider.forecastWindow == null,
                isDark: isDark,
              ),
              if (_hasForecast(pointData, key)) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in _forecastWindows.entries)
                      _forecastTile(
                        label: entry.value,
                        window: entry.key,
                        pointData: pointData,
                        layer: key,
                        unit: unit,
                        active: provider.forecastWindow == entry.key,
                        isDark: isDark,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  static const Map<String, String> _forecastWindows = {
    '5day': '5D ahead',
    '10day': '10D ahead',
    '15day': '15D ahead',
  };

  bool _hasForecast(PointData data, String layer) {
    return _forecastWindows.keys
        .any((window) => _forecastValue(data, layer, window) != null);
  }

  Widget _forecastTile({
    required String label,
    required String window,
    required PointData pointData,
    required String layer,
    required String unit,
    required bool active,
    required bool isDark,
  }) {
    return _valueTile(
      label: label,
      value: _forecastValue(pointData, layer, window),
      layer: layer,
      unit: unit,
      active: active,
      isDark: isDark,
      compact: true,
    );
  }

  Widget _valueTile({
    required String label,
    required double? value,
    required String layer,
    required String unit,
    required bool active,
    required bool isDark,
    bool compact = false,
  }) {
    final color = _getValueColor(layer, value);
    final labelColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: compact ? null : double.infinity,
      constraints: BoxConstraints(minWidth: compact ? 96 : 0),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 9 : 10,
      ),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.brandPrimary.withOpacity(isDark ? 0.24 : 0.12)
            : isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? AppTheme.brandPrimary
              : isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.07),
        ),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: labelColor)),
                const SizedBox(height: 5),
                _valueChip(value, unit, color, compact: true),
              ],
            )
          : Row(
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: labelColor),
                ),
                const Spacer(),
                _valueChip(value, unit, color),
              ],
            ),
    );
  }

  Widget _valueChip(
    double? value,
    String unit,
    Color color, {
    bool compact = false,
  }) {
    if (value == null) {
      return Text(
        'No data',
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${value.toStringAsFixed(3)}${unit.isEmpty ? '' : ' $unit'}',
        style: TextStyle(
          color: _textColorFor(color),
          fontWeight: FontWeight.w800,
          fontSize: compact ? 11 : 13,
        ),
      ),
    );
  }

  double? _forecastValue(PointData data, String layer, String window) {
    final forecast = data.forecast;
    if (forecast == null) return null;

    if (layer == 'savi') {
      final kc = _forecastValue(data, 'kc', window);
      if (kc == null) return null;
      return (kc - 0.5375) / 1.2088;
    }

    final byLayer = forecast[layer];
    if (byLayer is! Map) return null;
    return _asDouble(byLayer[window]);
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Color _textColorFor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.52 ? Colors.black : Colors.white;
  }

  Color _getValueColor(String layer, double? value) {
    if (value == null) return Colors.grey;
    switch (layer) {
      case 'savi':
        return value > 0.3
            ? Colors.green
            : value > 0
                ? Colors.yellow.shade700
                : Colors.red;
      case 'kc':
        return value > 0.8 ? Colors.green.shade700 : Colors.orange;
      case 'etc':
        return value > 7.5 ? Colors.deepPurple.shade400 : Colors.cyan;
      case 'cwr':
      case 'iwr':
        return value > 5 ? Colors.blue.shade700 : Colors.cyan;
      default:
        return AppTheme.brandPrimary;
    }
  }

  String _formatCoord(double value, String positive, String negative) {
    final hemi = value >= 0 ? positive : negative;
    return '${value.abs().toStringAsFixed(5)} deg $hemi';
  }
}

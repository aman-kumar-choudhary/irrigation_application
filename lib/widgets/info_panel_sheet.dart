import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/point_data_model.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

const List<String> _forecastLayerKeys = ['cwr', 'iwr'];

// ─────────────────────────────────────────────────────────────────────────────
// InfoPanelSheet — compact 1/3-screen point-data panel
//
// Design:
//  • Dark glass surface matching screenshot aesthetic
//  • Location + date meta row at top
//  • Horizontal scrollable layer value chips (SAVI / Kc / ETc / CWR / IWR)
//  • Forecast window selector tabs below each active layer
//  • Intentionally compact so it occupies ~1/3 of screen height
// ─────────────────────────────────────────────────────────────────────────────
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

    final radius = floating
        ? BorderRadius.circular(20)
        : const BorderRadius.vertical(top: Radius.circular(20));

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF07121E), Color(0xFF0D1F30)],
              )
            : null,
        color: isDark ? null : Colors.white,
        borderRadius: radius,
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.10)
              : AppTheme.lightBorder,
        ),
      ),
      child: SafeArea(
        top: floating,
        child: data == null
            ? _emptyState(provider, isDark)
            : _content(context, provider, data, isDark),
      ),
    );
  }

  // ── empty / loading state ─────────────────────────────────────────────────
  Widget _emptyState(AppProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: provider.pointLoading
            ? const CircularProgressIndicator.adaptive()
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 20,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    provider.pointError ?? 'Tap on the map to inspect a pixel',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── main content ─────────────────────────────────────────────────────────
  Widget _content(
    BuildContext context,
    AppProvider provider,
    PointData data,
    bool isDark,
  ) {
    final displayDate = provider.selectedDate != null
        ? DateFormat('d MMM yyyy').format(provider.selectedDate!)
        : data.acquisitionDate;
    final displayLayers = _displayLayers(data);

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // drag handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.18)
                  : Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // ── header row ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 2, 8, 8),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.brandTeal.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.brandTeal.withOpacity(0.38)),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppTheme.brandTeal,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_formatCoord(data.lat, 'N', 'S')},  ${_formatCoord(data.lon, 'E', 'W')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'JetBrains Mono',
                        color: isDark ? Colors.white : AppTheme.lightText,
                      ),
                    ),
                    if (displayDate != null)
                      Text(
                        displayDate,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                  ],
                ),
              ),
              // close button
              GestureDetector(
                onTap: () => _close(context, provider),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.10)
                          : Colors.black.withOpacity(0.08),
                    ),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 14, endIndent: 14),
        // ── layer value chips ────────────────────────────────────────────────
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0;
                    i < displayLayers.length;
                    i++) ...[
                  _LayerValueChip(
                    layer: displayLayers[i],
                    data: data,
                    isDark: isDark,
                  ),
                  if (i < displayLayers.length - 1)
                    const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        // ── forecast windows (only when forecast data exists) ────────────────
        if (_anyForecast(data)) ...[
          const Divider(height: 1, indent: 14, endIndent: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: _ForecastRow(
              data: data,
              provider: provider,
              isDark: isDark,
            ),
          ),
        ],
      ],
    );
  }

  bool _anyForecast(PointData data) {
    final forecast = data.forecast;
    if (forecast == null) return false;
    return _forecastLayerKeys.any((key) {
      final byLayer = forecast[key];
      return byLayer is Map && byLayer.values.any((value) => value != null);
    });
  }

  String _formatCoord(double value, String positive, String negative) {
    final hemi = value >= 0 ? positive : negative;
    return '${value.abs().toStringAsFixed(4)}° $hemi';
  }

  List<Map<String, dynamic>> _displayLayers(PointData data) {
    final configured = Constants.layerDefinitions
        .where((layer) => data.values.containsKey(layer['key']))
        .toList();
    final configuredKeys =
        configured.map((layer) => layer['key'] as String).toSet();
    final extras = data.values.keys
        .where((key) => !configuredKeys.contains(key))
        .map(
          (key) => {
            'key': key,
            'name': key.toUpperCase(),
            'unit': '',
          },
        );
    return [...configured, ...extras];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layer value chip — compact card showing layer name + value badge
// ─────────────────────────────────────────────────────────────────────────────
class _LayerValueChip extends StatelessWidget {
  final Map<String, dynamic> layer;
  final PointData data;
  final bool isDark;

  const _LayerValueChip({
    required this.layer,
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final key = layer['key'] as String;
    final unit = layer['unit'] as String? ?? '';
    final value = data.values[key];
    final color = _valueColor(key, value);

    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.09)
              : Colors.black.withOpacity(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // layer key
          Text(
            key.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 6),
          // value badge
          if (value == null)
            Text(
              'N/A',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white30 : Colors.black38,
              ),
            )
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                unit.isEmpty
                    ? value.toStringAsFixed(3)
                    : '${value.toStringAsFixed(2)} $unit',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: _textOn(color),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _valueColor(String key, double? value) {
    if (value == null) return Colors.grey;
    switch (key) {
      case 'savi':
        return value > 0.3
            ? const Color(0xFF2E7D32)
            : value > 0
                ? const Color(0xFFF9A825)
                : const Color(0xFFB71C1C);
      case 'kc':
        return value > 0.8
            ? const Color(0xFF1B5E20)
            : const Color(0xFFE65100);
      case 'etc':
        return value > 7.5
            ? const Color(0xFF4527A0)
            : const Color(0xFF00838F);
      case 'cwr':
      case 'iwr':
        return value > 5
            ? const Color(0xFF0D47A1)
            : const Color(0xFF006064);
      default:
        return AppTheme.brandPrimary;
    }
  }

  Color _textOn(Color bg) =>
      bg.computeLuminance() > 0.45 ? Colors.black : Colors.white;
}

// ─────────────────────────────────────────────────────────────────────────────
// Forecast row — 5D / 10D / 15D ahead chips for CWR and IWR only
// ─────────────────────────────────────────────────────────────────────────────
class _ForecastRow extends StatelessWidget {
  final PointData data;
  final AppProvider provider;
  final bool isDark;

  static const Map<String, String> _windows = {
    '5day': '5D ahead',
    '10day': '10D ahead',
    '15day': '15D ahead',
  };

  const _ForecastRow({
    required this.data,
    required this.provider,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SARIMAX FORECAST',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: isDark ? Colors.white30 : Colors.black38,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final entry in _windows.entries) ...[
                _ForecastWindowCard(
                  window: entry.key,
                  label: entry.value,
                  data: data,
                  active: provider.forecastWindow == entry.key,
                  isDark: isDark,
                  onTap: () {
                    if (provider.forecastWindow == entry.key) {
                      provider.setForecastWindow(null);
                    } else {
                      provider.setForecastWindow(entry.key);
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ForecastWindowCard extends StatelessWidget {
  final String window;
  final String label;
  final PointData data;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  const _ForecastWindowCard({
    required this.window,
    required this.label,
    required this.data,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // collect values for this forecast window
    final forecast = data.forecast;
    final entries = <String, double?>{};
    for (final key in _forecastLayerKeys) {
      final byLayer = forecast?[key];
      double? val;
      if (byLayer is Map) {
        final raw = byLayer[window];
        if (raw is num) val = raw.toDouble();
      }
      entries['${key.toUpperCase()} (mm)'] = val;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.brandPrimary.withOpacity(isDark ? 0.24 : 0.12)
              : isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppTheme.brandPrimary.withOpacity(0.55)
                : isDark
                    ? Colors.white.withOpacity(0.09)
                    : Colors.black.withOpacity(0.07),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: active
                    ? AppTheme.brandTeal
                    : isDark
                        ? Colors.white60
                        : Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            for (final e in entries.entries) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.key,
                    style: TextStyle(
                      fontSize: 9.5,
                      color:
                          isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    e.value == null
                        ? '—'
                        : e.value!.toStringAsFixed(3),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'JetBrains Mono',
                      color: active
                          ? Colors.white
                          : isDark
                              ? Colors.white70
                              : AppTheme.lightText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/chart_data_model.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChartWidget
//
// Fixes:
//  • Dropdown uses showMenu() so it renders outside the chip boundary (no clipping)
//  • Monthly tooltip shows "Mon YYYY · value"
//  • Cumulative tooltip shows "Mon · value"
//  • Chart opens centred via showDialog (full-height modal) — handled in dashboard
//  • Mobile-friendly: flexible heights, no hard-coded pixel sizes that clip
// ─────────────────────────────────────────────────────────────────────────────
class ChartWidget extends StatefulWidget {
  const ChartWidget({super.key});

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  String selectedLayer = 'savi';
  String mode = 'monthly';
  ChartData? chartData;
  bool loading = false;
  String? error;

  static const List<Color> _yearColors = [
    Color(0xFF3B9FD9),
    Color(0xFF19C7A6),
    Color(0xFFD97706),
    Color(0xFFC2410C),
    Color(0xFF7C3AED),
    Color(0xFF0F766E),
    Color(0xFFB91C1C),
    Color(0xFF4B5563),
  ];

  static const Map<String, String> _shortNames = {
    'savi': 'SAVI',
    'kc': 'Kc',
    'etc': 'ETc',
    'cwr': 'CWR',
    'iwr': 'IWR',
  };

  static const Map<String, String> _fullNames = {
    'savi': 'Soil Adjusted Vegetation Index',
    'kc': 'Crop Coefficient',
    'etc': 'Evapotranspiration',
    'cwr': 'Crop Water Requirement',
    'iwr': 'Irrigation Water Requirement',
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await ApiService().fetchChartData(selectedLayer, mode);
      setState(() {
        chartData = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  // ── Dropdown via showMenu so it renders in the Overlay (outside any clip) ──
  void _openLayerMenu(BuildContext context, RenderBox chipBox) async {
    final isDark = context.read<AppProvider>().isDark;
    final chipOffset = chipBox.localToGlobal(Offset.zero);
    final chipSize = chipBox.size;

    final selected = await showMenu<String>(
      context: context,
      color: isDark ? const Color(0xFF0E1E2C) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      position: RelativeRect.fromLTRB(
        chipOffset.dx,
        chipOffset.dy + chipSize.height + 4,
        chipOffset.dx + chipSize.width,
        chipOffset.dy + chipSize.height + 4 + 300,
      ),
      items: _shortNames.entries.map((e) {
        final isActive = e.key == selectedLayer;
        return PopupMenuItem<String>(
          value: e.key,
          height: 44,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.brandTeal.withOpacity(0.18)
                      : AppTheme.brandTeal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.brandTeal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _fullNames[e.key] ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isDark ? Colors.white : AppTheme.lightText,
                  ),
                ),
              ),
              if (isActive)
                Icon(Icons.check_rounded,
                    size: 14, color: AppTheme.brandTeal),
            ],
          ),
        );
      }).toList(),
    );

    if (selected != null && selected != selectedLayer) {
      setState(() => selectedLayer = selected);
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDark;

    return Column(
      children: [
        // ── toolbar ──────────────────────────────────────────────────────────
        _Toolbar(
          selectedLayer: selectedLayer,
          mode: mode,
          isDark: isDark,
          shortNames: _shortNames,
          fullNames: _fullNames,
          onOpenLayerMenu: _openLayerMenu,
          onModeChanged: (val) {
            setState(() => mode = val);
            _fetchData();
          },
        ),
        const SizedBox(height: 6),
        // ── chart body ───────────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 12, 6),
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.brandTeal,
                      strokeWidth: 2.5,
                    ),
                  )
                : error != null
                    ? _ErrorState(message: error!, isDark: isDark)
                    : chartData == null
                        ? const SizedBox()
                        : mode == 'monthly'
                            ? _MonthlyChart(
                                data: chartData!,
                                isDark: isDark,
                                layerKey: selectedLayer,
                              )
                            : _CumulativeChart(
                                data: chartData!,
                                isDark: isDark,
                                yearColors: _yearColors,
                              ),
          ),
        ),
        // ── year legend (cumulative only) ────────────────────────────────────
        if (!loading &&
            error == null &&
            chartData != null &&
            mode == 'cumulative')
          _YearLegend(
            data: chartData!,
            yearColors: _yearColors,
            isDark: isDark,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toolbar
// Layer selection: tappable chip → showMenu (renders outside bounds)
// Mode: M / C pill buttons
// ─────────────────────────────────────────────────────────────────────────────
class _Toolbar extends StatelessWidget {
  final String selectedLayer;
  final String mode;
  final bool isDark;
  final Map<String, String> shortNames;
  final Map<String, String> fullNames;
  final void Function(BuildContext context, RenderBox chipBox) onOpenLayerMenu;
  final ValueChanged<String> onModeChanged;

  const _Toolbar({
    required this.selectedLayer,
    required this.mode,
    required this.isDark,
    required this.shortNames,
    required this.fullNames,
    required this.onOpenLayerMenu,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final chipBg = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.04);
    final chipBorder = isDark
        ? Colors.white.withOpacity(0.14)
        : Colors.black.withOpacity(0.09);
    final labelColor = isDark ? Colors.white70 : AppTheme.lightText;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Row(
        children: [
          // ── layer selector chip (tap → showMenu) ─────────────────────────
          Expanded(
            child: Builder(
              builder: (ctx) => GestureDetector(
                onTap: () {
                  final box = ctx.findRenderObject() as RenderBox?;
                  if (box != null) onOpenLayerMenu(ctx, box);
                },
                child: Container(
                  height: 36,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: chipBorder, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.brandTeal.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          shortNames[selectedLayer] ?? selectedLayer,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.brandTeal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          fullNames[selectedLayer] ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.expand_more_rounded,
                        size: 16,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // ── mode pills ───────────────────────────────────────────────────
          Container(
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: chipBorder, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ModeButton(
                  label: 'M',
                  tooltip: 'Monthly',
                  value: 'monthly',
                  current: mode,
                  isDark: isDark,
                  onTap: () => onModeChanged('monthly'),
                ),
                _ModeButton(
                  label: 'C',
                  tooltip: 'Cumulative',
                  value: 'cumulative',
                  current: mode,
                  isDark: isDark,
                  onTap: () => onModeChanged('cumulative'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final String value;
  final String current;
  final bool isDark;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.tooltip,
    required this.value,
    required this.current,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = current == value;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppTheme.brandPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: active
                  ? Colors.white
                  : isDark
                      ? Colors.white38
                      : Colors.black38,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Monthly chart — tooltip shows "Mon YYYY · value"
// Bottom axis alternates month abbrev + year label
// ─────────────────────────────────────────────────────────────────────────────
class _MonthlyChart extends StatelessWidget {
  final ChartData data;
  final bool isDark;
  final String layerKey;

  const _MonthlyChart({
    required this.data,
    required this.isDark,
    required this.layerKey,
  });

  /// Builds a flat list of (yearIdx, monthIdx) so we can reverse-map x → label
  List<(int yearIdx, int monthIdx)> get _indexMap {
    final list = <(int, int)>[];
    for (int y = 0; y < data.data.length; y++) {
      for (int m = 0; m < data.data[y].monthly.length; m++) {
        list.add((y, m));
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final indexMap = _indexMap;
    final spots = <FlSpot>[];
    for (int x = 0; x < indexMap.length; x++) {
      final (yi, mi) = indexMap[x];
      final v = data.data[yi].monthly[mi];
      if (v != null) spots.add(FlSpot(x.toDouble(), v));
    }

    if (spots.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final ySpan = (maxY - minY).abs();
    final safeMinY = ySpan == 0 ? minY - 1 : minY - ySpan * 0.12;
    final safeMaxY = ySpan == 0 ? maxY + 1 : maxY + ySpan * 0.12;
    final totalPts = indexMap.length.clamp(1, 9999);
    final mn = data.monthNames.isEmpty ? 1 : data.monthNames.length;

    final gridColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: ySpan == 0 ? 1 : ySpan / 4,
          verticalInterval: mn.toDouble(),
          getDrawingHorizontalLine: (_) =>
              FlLine(color: gridColor, strokeWidth: 1),
          getDrawingVerticalLine: (_) =>
              FlLine(color: gridColor, strokeWidth: 0.6, dashArray: [4, 4]),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: mn.toDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= indexMap.length) return const SizedBox();
                final (yi, _) = indexMap[idx];
                // Show year at start of each year's data block
                final year = data.years.length > yi ? data.years[yi] : '';
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 1,
                        height: 5,
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$year',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (totalPts - 1).toDouble(),
        minY: safeMinY,
        maxY: safeMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: const Color(0xFF3B9FD9),
            barWidth: 2.2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 2.5,
                color: Colors.white,
                strokeWidth: 1.5,
                strokeColor: const Color(0xFF3B9FD9),
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF3B9FD9).withOpacity(0.22),
                  const Color(0xFF3B9FD9).withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor:
                isDark ? const Color(0xFF0E1E2C) : Colors.white,
            tooltipBorder: BorderSide(
              color: const Color(0xFF3B9FD9).withOpacity(0.5),
            ),
            tooltipRoundedRadius: 10,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                final x = s.x.toInt();
                String label = s.y.toStringAsFixed(3);
                if (x >= 0 && x < indexMap.length) {
                  final (yi, mi) = indexMap[x];
                  final year = data.years.length > yi ? '${data.years[yi]}' : '';
                  final month = data.monthNames.length > mi
                      ? data.monthNames[mi].substring(0, 3)
                      : '';
                  label = '$month $year\n${s.y.toStringAsFixed(3)}';
                }
                return LineTooltipItem(
                  label,
                  const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF3B9FD9),
                    height: 1.5,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cumulative chart — tooltip shows "Mon · value"
// ─────────────────────────────────────────────────────────────────────────────
class _CumulativeChart extends StatelessWidget {
  final ChartData data;
  final bool isDark;
  final List<Color> yearColors;

  const _CumulativeChart({
    required this.data,
    required this.isDark,
    required this.yearColors,
  });

  @override
  Widget build(BuildContext context) {
    final validEntries = data.data.asMap().entries.where((entry) {
      return entry.value.cumulative.any((e) => e != null);
    }).toList();

    final lines = validEntries.map((entry) {
      final idx = entry.key;
      final yearData = entry.value;
      final spots = yearData.cumulative
          .asMap()
          .entries
          .where((e) => e.value != null)
          .map((e) => FlSpot(e.key.toDouble(), e.value!))
          .toList();

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.3,
        color: yearColors[idx % yearColors.length],
        barWidth: 2.6,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 2.5,
            color: Colors.white,
            strokeWidth: 1.5,
            strokeColor: yearColors[idx % yearColors.length],
          ),
        ),
      );
    }).toList();

    if (lines.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final gridColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: gridColor, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.monthNames.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    data.monthNames[idx].substring(0, 3),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: lines,
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor:
                isDark ? const Color(0xFF0E1E2C) : Colors.white,
            tooltipBorder: const BorderSide(color: Color(0xFF19C7A6), width: 0.8),
            tooltipRoundedRadius: 10,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                final mi = s.x.toInt();
                final month = (mi >= 0 && mi < data.monthNames.length)
                    ? data.monthNames[mi].substring(0, 3)
                    : '';
                
                final bi = s.barIndex;
                final originalIdx = (bi >= 0 && bi < validEntries.length) 
                    ? validEntries[bi].key 
                    : bi;
                    
                final year = (originalIdx >= 0 && originalIdx < data.years.length)
                    ? '${data.years[originalIdx]}'
                    : '';
                final lineColor = yearColors[originalIdx % yearColors.length];
                
                return LineTooltipItem(
                  '$month $year\n${s.y.toStringAsFixed(2)}',
                  TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: lineColor,
                    height: 1.5,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Year legend strip for cumulative mode
// ─────────────────────────────────────────────────────────────────────────────
class _YearLegend extends StatelessWidget {
  final ChartData data;
  final List<Color> yearColors;
  final bool isDark;

  const _YearLegend({
    required this.data,
    required this.yearColors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: data.years.asMap().entries.map((e) {
          final color = yearColors[e.key % yearColors.length];
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${e.value}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final bool isDark;

  const _ErrorState({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 32,
                color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.red.shade300 : Colors.red.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/chart_data_model.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

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

  final List<Color> yearColors = [
    const Color(0xFF0f4c81),
    const Color(0xFF1f7a5c),
    const Color(0xFFd97706),
    const Color(0xFFc2410c),
    const Color(0xFF0f766e),
    const Color(0xFFb91c1c),
    const Color(0xFF7c3aed),
    const Color(0xFF4b5563),
  ];

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

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDark;

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 360;

          return Column(
            children: [
              if (narrow)
                Column(
                  children: [
                    _layerPicker(isDark),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _modePicker(isDark),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: _layerPicker(isDark)),
                    const SizedBox(width: 12),
                    _modePicker(isDark),
                  ],
                ),
              const SizedBox(height: 20),
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.brandTeal,
                        ),
                      )
                    : error != null
                        ? Center(
                            child: Text(
                              error!,
                              style: TextStyle(
                                color:
                                    isDark ? Colors.red.shade300 : Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : chartData == null
                            ? const SizedBox()
                            : mode == 'monthly'
                                ? _buildMonthlyChart(isDark)
                                : _buildCumulativeChart(isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _layerPicker(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface3 : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedLayer,
          isExpanded: true,
          dropdownColor: isDark ? AppTheme.darkSurface3 : Colors.white,
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
            fontSize: 14,
          ),
          items: const [
            DropdownMenuItem(value: 'savi', child: Text('SAVI')),
            DropdownMenuItem(value: 'kc', child: Text('Kc')),
            DropdownMenuItem(value: 'etc', child: Text('ETc')),
            DropdownMenuItem(value: 'cwr', child: Text('CWR')),
            DropdownMenuItem(value: 'iwr', child: Text('IWR')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => selectedLayer = val);
              _fetchData();
            }
          },
        ),
      ),
    );
  }

  Widget _modePicker(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface3 : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeButton('monthly', 'Monthly', isDark),
          _modeButton('cumulative', 'Cumulative', isDark),
        ],
      ),
    );
  }

  Widget _modeButton(String value, String label, bool isDark) {
    final isActive = mode == value;
    return GestureDetector(
      onTap: () {
        setState(() => mode = value);
        _fetchData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.brandPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive
                ? Colors.white
                : isDark
                    ? AppTheme.darkTextMuted
                    : AppTheme.lightTextMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(bool isDark) {
    final data = chartData!;
    final spots = <FlSpot>[];
    int x = 0;

    for (final yearData in data.data) {
      for (int i = 0; i < yearData.monthly.length; i++) {
        if (yearData.monthly[i] != null) {
          spots.add(FlSpot(x.toDouble(), yearData.monthly[i]!));
        }
        x++;
      }
    }

    if (spots.isEmpty) return const Center(child: Text('No data'));

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final ySpan = (maxY - minY).abs();
    final safeMinY = ySpan == 0 ? minY - 1 : minY - ySpan * 0.1;
    final safeMaxY = ySpan == 0 ? maxY + 1 : maxY + ySpan * 0.1;
    final totalMonths = data.monthNames.length * data.years.length;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ySpan == 0 ? 1 : ySpan / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, _) => Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 10,
                  color:
                      isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 3,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= totalMonths || data.monthNames.isEmpty) {
                  return const SizedBox();
                }
                final yearIdx = idx ~/ data.monthNames.length;
                final monthIdx = idx % data.monthNames.length;
                if (yearIdx >= data.years.length) return const SizedBox();
                return Text(
                  '${data.monthNames[monthIdx].substring(0, 3)}\n${data.years[yearIdx]}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark
                        ? AppTheme.darkTextMuted
                        : AppTheme.lightTextMuted,
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
        maxX: (totalMonths > 0 ? totalMonths - 1 : spots.length - 1).toDouble(),
        minY: safeMinY,
        maxY: safeMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF3b9fd9),
            barWidth: 2.8,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF3b9fd9).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCumulativeChart(bool isDark) {
    final data = chartData!;
    final lines = data.data
        .asMap()
        .entries
        .map((entry) {
          final idx = entry.key;
          final yearData = entry.value;
          final spots = yearData.cumulative
              .asMap()
              .entries
              .where((e) => e.value != null)
              .map((e) => FlSpot(e.key.toDouble(), e.value!))
              .toList();
          if (spots.isEmpty) return null;
          return LineChartBarData(
            spots: spots,
            isCurved: true,
            color: yearColors[idx % yearColors.length],
            barWidth: 2.6,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          );
        })
        .whereType<LineChartBarData>()
        .toList();

    if (lines.isEmpty) return const Center(child: Text('No data'));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, _) => Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 10,
                  color:
                      isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.monthNames.length) {
                  return const SizedBox();
                }
                return Text(
                  data.monthNames[idx].substring(0, 3),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppTheme.darkTextMuted
                        : AppTheme.lightTextMuted,
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/map_view.dart';
import '../widgets/layer_control_sheet.dart';
import '../widgets/info_panel_sheet.dart';
import '../widgets/weather_panel.dart';
import '../widgets/calendar_sheet.dart';
import '../widgets/chart_widget.dart';
import '../widgets/adaptive_overlay_panel.dart';

enum _UtilityPanel { layers, weather }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MapController _mapController = MapController();
  LatLng? _lastShownInfoLocation;
  _UtilityPanel? _utilityPanel;
  bool _calendarOpen = false;
  bool _chartOpen = false;
  bool _infoCardOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadHistory();
      context.read<AppProvider>().fetchWeather();
    });
  }

  void _toggleUtilityPanel(_UtilityPanel panel) {
    setState(() {
      _utilityPanel = _utilityPanel == panel ? null : panel;
    });
  }

  void _toggleCalendarPanel() {
    setState(() => _calendarOpen = !_calendarOpen);
  }

  void _toggleChartPanel() {
    setState(() => _chartOpen = !_chartOpen);
  }

  void _closeInfoPanel() {
    setState(() {
      _infoCardOpen = false;
      _lastShownInfoLocation = null;
    });
  }

  void _closeCalendarPanel() {
    setState(() => _calendarOpen = false);
  }

  void _closeChartPanel() {
    setState(() => _chartOpen = false);
  }

  void _closeUtilityPanel() {
    setState(() => _utilityPanel = null);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;

    // Show point information automatically when map data arrives.
    if (provider.pointData != null &&
        !provider.pointLoading &&
        provider.selectedLocation != null &&
        provider.selectedLocation != _lastShownInfoLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _lastShownInfoLocation = provider.selectedLocation;
          _infoCardOpen = true;
        });
      });
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final landscape = constraints.maxWidth > constraints.maxHeight;
          final useSideChart = !compact || landscape;
          final utilityPanelHeight = constraints.maxHeight * 0.34;
          final chartBottomMargin =
              _utilityPanel == null ? 12.0 : utilityPanelHeight + 24;
          final locationBottom =
              _utilityPanel == null ? 84.0 : utilityPanelHeight + 28;
          final topPanelMargin = compact ? 118.0 : 84.0;

          return Stack(
            children: [
              RepaintBoundary(
                child: MapView(mapController: _mapController),
              ),
              if (_infoCardOpen && provider.pointData != null)
                FloatingWorkspacePanel(
                  initialHeightFraction: compact ? 0.34 : 0.38,
                  minHeightFraction: 0.24,
                  maxHeightFraction: 0.62,
                  maxWidth: 390,
                  margin: EdgeInsets.fromLTRB(
                    12,
                    topPanelMargin,
                    12,
                    12,
                  ),
                  child: InfoPanelSheet(
                    floating: true,
                    onClose: _closeInfoPanel,
                  ),
                ),
              if (_calendarOpen)
                FloatingWorkspacePanel(
                  alignment: Alignment.topCenter,
                  initialHeightFraction: compact ? 0.54 : 0.58,
                  minHeightFraction: 0.34,
                  maxHeightFraction: 0.72,
                  maxWidth: 460,
                  margin: EdgeInsets.fromLTRB(
                    12,
                    topPanelMargin,
                    12,
                    12,
                  ),
                  child: CalendarSheet(onClose: _closeCalendarPanel),
                ),
              if (_chartOpen)
                useSideChart
                    ? ResizableSideDrawer(
                        initialFraction: landscape ? 0.42 : 0.36,
                        minFraction: 0.30,
                        maxFraction: 0.62,
                        child: _ChartPanel(
                          isDark: isDark,
                          onClose: _closeChartPanel,
                        ),
                      )
                    : DraggableBottomPanel(
                        initialFraction: 0.38,
                        minFraction: 0.28,
                        maxFraction: 0.74,
                        maxWidth: 900,
                        margin: EdgeInsets.fromLTRB(
                          12,
                          0,
                          12,
                          chartBottomMargin,
                        ),
                        child: _ChartPanel(
                          isDark: isDark,
                          onClose: _closeChartPanel,
                        ),
                      ),
              if (_utilityPanel != null)
                DraggableBottomPanel(
                  initialFraction: 0.34,
                  minFraction: 0.24,
                  maxFraction: 0.70,
                  child: _utilityPanel == _UtilityPanel.layers
                      ? LayerControlSheet(onClose: _closeUtilityPanel)
                      : WeatherPanel(onClose: _closeUtilityPanel),
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: _dashboardHeader(provider, isDark, compact),
                ),
              ),
              Positioned(
                bottom: locationBottom,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'location',
                  mini: true,
                  backgroundColor:
                      isDark ? const Color(0xFF091722) : Colors.white,
                  onPressed: () {
                    _mapController.move(const LatLng(29.0, 79.4), 12);
                  },
                  child: Icon(
                    Icons.my_location,
                    color: isDark ? AppTheme.brandTeal : AppTheme.brandPrimary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dashboardHeader(
    AppProvider provider,
    bool isDark,
    bool compact,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
      decoration: BoxDecoration(
        color:
            isDark ? const Color(0xF0081420) : Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.10),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _headerIconButton(
                icon: Icons.menu,
                isDark: isDark,
                active: _utilityPanel == _UtilityPanel.layers,
                onTap: () => _toggleUtilityPanel(_UtilityPanel.layers),
              ),
              const SizedBox(width: 6),
              _headerIconButton(
                icon: Icons.home_outlined,
                isDark: isDark,
                onTap: () => provider.setIndex(0),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _dashLogo(
                        'assets/icons/iirs.png', 'IIRS', compact ? 28 : 34),
                    Container(
                      width: 1,
                      height: 26,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color:
                          isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    ),
                    _dashLogo(
                        'assets/icons/isro.png', 'ISRO', compact ? 28 : 34),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _headerIconButton(
                icon: provider.isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                isDark: isDark,
                onTap: provider.toggleTheme,
              ),
            ],
          ),
          const SizedBox(height: 7),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _weatherHeaderCard(provider, isDark),
                const SizedBox(width: 7),
                _headerPill(
                  icon: Icons.show_chart,
                  label: _chartOpen ? 'Back' : 'Crop trends',
                  isDark: isDark,
                  active: _chartOpen,
                  onTap: _toggleChartPanel,
                ),
                const SizedBox(width: 7),
                _headerPill(
                  icon: Icons.calendar_today_outlined,
                  label: provider.selectedDate != null
                      ? DateFormat('dd MMM').format(provider.selectedDate!)
                      : 'Today',
                  isDark: isDark,
                  active: provider.selectedDate != null || _calendarOpen,
                  onTap: _toggleCalendarPanel,
                ),
                if (provider.forecastWindow != null) ...[
                  const SizedBox(width: 7),
                  _headerPill(
                    icon: Icons.timeline,
                    label: _forecastLabel(provider.forecastWindow),
                    isDark: isDark,
                    active: true,
                    onTap: () => _toggleUtilityPanel(_UtilityPanel.layers),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherHeaderCard(AppProvider provider, bool isDark) {
    final weather = provider.weatherData;
    final selected =
        weather == null || weather.daily.isEmpty ? null : weather.daily.first;
    final date = selected == null
        ? 'Today'
        : DateFormat('dd MMM').format(DateTime.parse(selected.date));

    return GestureDetector(
      onTap: () => _toggleUtilityPanel(_UtilityPanel.weather),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(
          minWidth: 148,
          maxWidth: 230,
          minHeight: 38,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: _utilityPanel == _UtilityPanel.weather
              ? AppTheme.brandPrimary.withOpacity(isDark ? 0.22 : 0.12)
              : Colors.white.withOpacity(isDark ? 0.06 : 0.86),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: _utilityPanel == _UtilityPanel.weather
                ? AppTheme.brandPrimary
                : isDark
                    ? AppTheme.darkBorder
                    : AppTheme.lightBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected?.emoji ?? '🌤️',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.userLocationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppTheme.darkTextSoft
                          : AppTheme.lightTextSoft,
                    ),
                  ),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFDCEFE4)
                          : AppTheme.brandPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              selected == null ? '--' : '${selected.tempMax.round()}°C',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerPill({
    required IconData icon,
    required String label,
    required bool isDark,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.brandPrimary.withOpacity(isDark ? 0.22 : 0.12)
              : Colors.white.withOpacity(isDark ? 0.06 : 0.86),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: active
                ? AppTheme.brandPrimary
                : isDark
                    ? AppTheme.darkBorder
                    : AppTheme.lightBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active
                  ? AppTheme.brandTeal
                  : isDark
                      ? AppTheme.darkTextMuted
                      : AppTheme.lightTextMuted,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active
                    ? (isDark ? AppTheme.darkText : AppTheme.brandPrimary)
                    : isDark
                        ? AppTheme.darkTextSoft
                        : AppTheme.lightTextSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: active
              ? AppTheme.brandPrimary.withOpacity(isDark ? 0.22 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppTheme.brandPrimary.withOpacity(0.45)
                : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: active
              ? AppTheme.brandTeal
              : isDark
                  ? AppTheme.darkTextMuted
                  : AppTheme.lightTextMuted,
        ),
      ),
    );
  }

  Widget _dashLogo(String asset, String fallback, double height) {
    return Image.asset(
      asset,
      height: height,
      width: 72,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Text(
        fallback,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppTheme.brandTeal,
        ),
      ),
    );
  }

  String _forecastLabel(String? window) {
    switch (window) {
      case '5day':
        return '5D ahead';
      case '10day':
        return '10D ahead';
      case '15day':
        return '15D ahead';
      default:
        return 'Observed';
    }
  }
}

class _ChartPanel extends StatelessWidget {
  final bool isDark;
  final VoidCallback onClose;

  const _ChartPanel({
    required this.isDark,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.28 : 0.16),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 10, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 20,
                    color: isDark ? AppTheme.brandTeal : AppTheme.brandPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Crop Trends',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: ChartWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

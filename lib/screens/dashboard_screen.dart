import 'dart:math';

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
import '../widgets/calendar_sheet.dart';
import '../widgets/chart_widget.dart';
import '../widgets/adaptive_overlay_panel.dart';

enum _UtilityPanel { layers }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MapController _mapController = MapController();
  _UtilityPanel? _utilityPanel;
  bool _calendarOpen = false;
  bool _chartOpen = false;
  Offset? _tapScreenPosition;
  
  GlobalKey _calendarButtonKey = GlobalKey();

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
    final compact = MediaQuery.of(context).size.width < 700;
    final landscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    if (compact && !landscape) {
      // Open as centered modal dialog on mobile portrait
      _openChartDialog();
    } else {
      setState(() => _chartOpen = !_chartOpen);
    }
  }

  void _openChartDialog() {
    final isDark = context.read<AppProvider>().isDark;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'chart',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (ctx, anim, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) {
        final screenH = MediaQuery.of(ctx).size.height;
        final screenW = MediaQuery.of(ctx).size.width;
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: screenW - 24,
              height: screenH * 0.72,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.32),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: _ChartPanel(
                isDark: isDark,
                onClose: () => Navigator.of(ctx).pop(),
              ),
            ),
          ),
        );
      },
    );
  }

  void _closeInfoPanel() {
    setState(() {
      _tapScreenPosition = null;
    });
    context.read<AppProvider>().clearPointData();
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

  void _showWeatherTooltip(AppProvider provider, BuildContext context) {
    final weather = provider.weatherData;
    if (weather == null || weather.daily.isEmpty) return;
    
    final today = weather.daily.first;
    
    showTooltip(
      context: context,
      message: '${today.emoji} ${today.tempMax.round()}°C, ${today.description}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (provider.selectedLocation != null && _tapScreenPosition != null) {
      // popup is shown via _tapScreenPosition
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final landscape = constraints.maxWidth > constraints.maxHeight;
          final useSideChart = !compact || landscape;
          final utilityPanelHeight = constraints.maxHeight * 0.34;
          final bottomMapInset = compact &&
                  !landscape &&
                  _utilityPanel != null
              ? utilityPanelHeight + 18
              : 0.0;
          final bottomSheetOpen = _utilityPanel != null;
          final chartBottomMargin =
              bottomSheetOpen ? utilityPanelHeight + 24 : 12.0;
          final locationBottom = 20.0; // Fixed position for location button
          final topPanelMargin = compact ? 118.0 : 84.0;
          final infoPanelWidth = constraints.maxWidth / 3;
          final maxLayerSidebarWidth =
              constraints.maxWidth - infoPanelWidth - 20;
          final preferredMinLayerWidth = compact ? 180.0 : 300.0;
          final preferredMaxLayerWidth = compact ? 360.0 : 420.0;
          final layerSidebarWidth =
              maxLayerSidebarWidth < preferredMinLayerWidth
                  ? maxLayerSidebarWidth
                  : maxLayerSidebarWidth.clamp(
                      preferredMinLayerWidth,
                      preferredMaxLayerWidth,
                    ).toDouble();
          final layerSidebarTop = MediaQuery.of(context).padding.top + 94;
          final infoPanelTop = MediaQuery.of(context).padding.top + 74;

          return Scaffold(
            body: Stack(
              children: [
                RepaintBoundary(
                  child: MapView(
                    mapController: _mapController,
                    bottomInset: bottomMapInset,
                    onTapScreenPosition: (pos) {
                      setState(() => _tapScreenPosition = pos);
                    },
                  ),
                ),
                // Small map popup — appears near tap point
                if (_tapScreenPosition != null && provider.selectedLocation != null)
                  _MapTapPopup(
                    tapPosition: _tapScreenPosition!,
                    provider: provider,
                    isDark: isDark,
                    onClose: _closeInfoPanel,
                    screenSize: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                if (_chartOpen)
                  ResizableSideDrawer(
                      initialFraction: landscape ? 0.44 : 0.38,
                      minFraction: 0.30,
                      maxFraction: 0.62,
                      child: _ChartPanel(
                        isDark: isDark,
                        onClose: _closeChartPanel,
                      ),
                    ),
                if (_utilityPanel != null)
                  Positioned(
                    top: layerSidebarTop,
                    left: 8,
                    bottom: 12,
                    width: layerSidebarWidth,
                    child: _OverlayShadow(
                      child: LayerControlSheet(onClose: _closeUtilityPanel),
                    ),
                  ),
                // Top Header Toolbar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _MobileOptimizedToolbar(
                          calendarButtonKey: _calendarButtonKey,
                          provider: provider,
                          isDark: isDark,
                          isMobile: isMobile,
                          utilityPanel: _utilityPanel,
                          calendarOpen: _calendarOpen,
                          chartOpen: _chartOpen,
                          onToggleLayers: () => _toggleUtilityPanel(_UtilityPanel.layers),
                          onToggleTheme: provider.toggleTheme,
                          onNavigateHome: () => provider.setIndex(0),
                          onShowWeather: () => _showWeatherTooltip(provider, context),
                          onToggleChart: _toggleChartPanel,
                          onToggleCalendar: _toggleCalendarPanel,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CalendarDropdownOverlay {
  OverlayEntry? _overlayEntry;
  final GlobalKey buttonKey;
  final VoidCallback onClose;
  final VoidCallback onClosed;

  _CalendarDropdownOverlay({
    required this.buttonKey,
    required this.onClose,
    required this.onClosed,
  });

  void show(BuildContext context) {
    _overlayEntry = _createOverlayEntry(context);
    Overlay.of(context).insert(_overlayEntry!);
  }

  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    onClosed();
  }

  OverlayEntry _createOverlayEntry(BuildContext context) {
    final renderBox = buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return OverlayEntry(builder: (_) => const SizedBox.shrink());
    }

    final buttonPosition = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    
    double left = buttonPosition.dx;
    double top = buttonPosition.dy + buttonSize.height + 4;
    
    const double dropdownWidth = 340;
    const double dropdownHeightCandidate = 460;
    final double maxDropdownHeight = screenSize.height - topPadding - 8;
    final double dropdownHeight = min(dropdownHeightCandidate, maxDropdownHeight);
    
    if (left + dropdownWidth > screenSize.width - 8) {
      left = screenSize.width - dropdownWidth - 8;
    }
    if (left < 8) {
      left = 8;
    }
    
    final double spaceBelow = screenSize.height - top;
    final double spaceAbove = buttonPosition.dy - topPadding;
    final bool showBelow = spaceBelow >= dropdownHeight || spaceBelow >= spaceAbove;
    
    if (!showBelow) {
      top = buttonPosition.dy - dropdownHeight - 4;
    }
    top = top.clamp(topPadding + 4, screenSize.height - dropdownHeight - 4);

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: hide,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.transparent,
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: dropdownWidth,
              height: dropdownHeight,
              child: Material(
                color: Colors.transparent,
                child: CalendarSheet(onClose: hide),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarSheet extends StatelessWidget {
  final VoidCallback? onClose;
  
  const CalendarSheet({super.key, this.onClose});
  
  @override
  Widget build(BuildContext context) {
    return FloatingMiniCalendar(onClose: onClose);
  }
}

void showTooltip({
  required BuildContext context,
  required String message,
}) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => _WeatherTooltip(
      message: message,
      onDismiss: () {},
    ),
  );
  
  overlay.insert(overlayEntry);
  
  Future.delayed(const Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}

class _WeatherTooltip extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _WeatherTooltip({
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_WeatherTooltip> createState() => _WeatherTooltipState();
}

class _WeatherTooltipState extends State<_WeatherTooltip> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 0,
      right: 0,
      child: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2A3A) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withOpacity(0.12) 
                        : Colors.black.withOpacity(0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_queue,
                      size: 16,
                      color: AppTheme.brandTeal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileOptimizedToolbar extends StatefulWidget {
  final GlobalKey calendarButtonKey;
  final AppProvider provider;
  final bool isDark;
  final bool isMobile;
  final _UtilityPanel? utilityPanel;
  final bool calendarOpen;
  final bool chartOpen;
  final VoidCallback onToggleLayers;
  final VoidCallback onToggleTheme;
  final VoidCallback onNavigateHome;
  final VoidCallback onShowWeather;
  final VoidCallback onToggleChart;
  final VoidCallback onToggleCalendar;

  const _MobileOptimizedToolbar({
    required this.calendarButtonKey,
    required this.provider,
    required this.isDark,
    required this.isMobile,
    required this.utilityPanel,
    required this.calendarOpen,
    required this.chartOpen,
    required this.onToggleLayers,
    required this.onToggleTheme,
    required this.onNavigateHome,
    required this.onShowWeather,
    required this.onToggleChart,
    required this.onToggleCalendar,
  });

  @override
  State<_MobileOptimizedToolbar> createState() => _MobileOptimizedToolbarState();
}

class _MobileOptimizedToolbarState extends State<_MobileOptimizedToolbar> {
  _CalendarDropdownOverlay? _overlay;

  @override
  void initState() {
    super.initState();
    _overlay = _CalendarDropdownOverlay(
      buttonKey: widget.calendarButtonKey,
      onClose: () {
        widget.onToggleCalendar();
      },
      onClosed: () {},
    );
  }

  @override
  void didUpdateWidget(_MobileOptimizedToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.calendarOpen != widget.calendarOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.calendarOpen) {
          _overlay?.show(context);
        } else {
          _overlay?.hide();
        }
      });
    }
  }

  @override
  void dispose() {
    _overlay?.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weather = widget.provider.weatherData;
    final selected = weather == null || weather.daily.isEmpty
        ? null
        : weather.daily.first;
    final tempLabel = selected == null
        ? '--'
        : '${selected.tempMax.round()}°';
    final weatherEmoji = selected?.emoji ?? '🌤';
    
    final hasSelectedDate = widget.provider.selectedDate != null;
    final dateLabel = hasSelectedDate && !widget.isMobile
        ? DateFormat('dd MMM').format(widget.provider.selectedDate!)
        : '';

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xDD0A1420)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withOpacity(0.12)
              : Colors.black.withOpacity(0.08),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.25 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolbarIconButton(
            icon: Icons.menu,
            active: widget.utilityPanel == _UtilityPanel.layers,
            isDark: widget.isDark,
            onTap: widget.onToggleLayers,
          ),
          _ToolbarIconButton(
            icon: Icons.home_outlined,
            active: false,
            isDark: widget.isDark,
            onTap: widget.onNavigateHome,
          ),
          _ToolbarIconButton(
            icon: widget.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            active: false,
            isDark: widget.isDark,
            onTap: widget.onToggleTheme,
          ),
          GestureDetector(
            onTap: widget.onShowWeather,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(weatherEmoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 2),
                  Text(
                    tempLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _ToolbarIconButton(
            icon: Icons.show_chart,
            active: widget.chartOpen,
            isDark: widget.isDark,
            onTap: widget.onToggleChart,
          ),
          Container(
            key: widget.calendarButtonKey,
            child: _ToolbarIconButton(
              icon: Icons.calendar_today_outlined,
              active: widget.calendarOpen || hasSelectedDate,
              isDark: widget.isDark,
              onTap: widget.onToggleCalendar,
            ),
          ),
          if (widget.provider.forecastWindow != null)
            _CompactForecastBadge(
              window: widget.provider.forecastWindow!,
              isDark: widget.isDark,
            ),
        ],
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  const _ToolbarIconButton({
    required this.icon,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.brandPrimary.withOpacity(isDark ? 0.24 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active
              ? AppTheme.brandTeal
              : isDark
                  ? Colors.white70
                  : Colors.black54,
        ),
      ),
    );
  }
}

class _CompactForecastBadge extends StatelessWidget {
  final String window;
  final bool isDark;

  const _CompactForecastBadge({
    required this.window,
    required this.isDark,
  });

  String _getLabel() {
    switch (window) {
      case '5day':
        return '5D';
      case '10day':
        return '10D';
      case '15day':
        return '15D';
      default:
        return 'FC';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.brandTeal.withOpacity(isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timeline,
            size: 10,
            color: AppTheme.brandTeal,
          ),
          const SizedBox(width: 2),
          Text(
            _getLabel(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppTheme.brandTeal,
            ),
          ),
        ],
      ),
    );
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
            // drag handle
            Container(
              margin: const EdgeInsets.only(top: 6, bottom: 2),
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // slim title row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 6, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 14,
                    color: isDark ? AppTheme.brandTeal : AppTheme.brandPrimary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Crop Trends',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: ChartWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayShadow extends StatelessWidget {
  final Widget child;

  const _OverlayShadow({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MapTapPopup — small floating bubble shown near the tapped map point
// Shows only: active layer name + value + date
// ─────────────────────────────────────────────────────────────────────────────
class _MapTapPopup extends StatefulWidget {
  final Offset tapPosition;
  final AppProvider provider;
  final bool isDark;
  final VoidCallback onClose;
  final Size screenSize;

  const _MapTapPopup({
    required this.tapPosition,
    required this.provider,
    required this.isDark,
    required this.onClose,
    required this.screenSize,
  });

  @override
  State<_MapTapPopup> createState() => _MapTapPopupState();
}

class _MapTapPopupState extends State<_MapTapPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _fade;

  static const double _popupW = 310;
  static const double _popupH = 160; // rough estimate
  static const double _arrowH = 8;
  static const double _margin = 12;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  /// Figure out x so popup doesn't overflow left/right
  double get _left {
    double x = widget.tapPosition.dx - _popupW / 2;
    x = x.clamp(_margin, widget.screenSize.width - _popupW - _margin);
    return x;
  }

  /// Figure out y — prefer showing popup above the tap
  double get _top {
    final above = widget.tapPosition.dy - _popupH - _arrowH - 8;
    if (above >= _margin) return above;
    // not enough space above → show below
    return widget.tapPosition.dy + _arrowH + 8;
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final data = provider.pointData;
    final isDark = widget.isDark;

    return Positioned(
      left: _left,
      top: _top,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          alignment: Alignment.bottomCenter,
          child: _PopupBubble(
            data: data,
            provider: provider,
            isDark: isDark,
            onClose: widget.onClose,
          ),
        ),
      ),
    );
  }
}

class _PopupBubble extends StatelessWidget {
  final dynamic data; // PointData?
  final AppProvider provider;
  final bool isDark;
  final VoidCallback onClose;

  const _PopupBubble({
    required this.data,
    required this.provider,
    required this.isDark,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xF0071320) : Colors.white;
    final border = isDark
        ? Colors.white.withOpacity(0.14)
        : Colors.black.withOpacity(0.10);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 310,
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.45 : 0.14),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: provider.pointLoading
            ? _loadingState(isDark)
            : data == null
                ? _errorState(provider, isDark)
                : _dataState(context, data, provider, isDark),
      ),
    );
  }

  Widget _loadingState(bool isDark) {
    return SizedBox(
      height: 48,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.brandTeal,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading…',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(AppProvider provider, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 14, color: Colors.orange.shade400),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                provider.pointError ?? 'No data',
                maxLines: 2,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
            _CloseBtn(onClose: onClose, isDark: isDark),
          ],
        ),
      ],
    );
  }

  Widget _dataState(
      BuildContext context, dynamic data, AppProvider provider, bool isDark) {
    // Collect only the active layer values
    final activeLayers = provider.layers.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    // If no layer is active, show all available values
    final keysToShow = activeLayers.isNotEmpty
        ? activeLayers.where((k) => data.values.containsKey(k)).toList()
        : (data.values as Map<String, dynamic>).keys.toList();

    // Date
    final displayDate = provider.selectedDate != null
        ? DateFormat('d MMM yyyy').format(provider.selectedDate!)
        : (data.acquisitionDate as String?);

    final subColor = isDark ? Colors.white54 : Colors.black54;
    final headerColor = isDark ? Colors.white30 : Colors.black38;
    final dividerColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.07);
    final rowBg = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.03);

    // Forecast windows & keys
    const forecastWindows = {'5day': '5D', '10day': '10D', '15day': '15D'};
    // All rows to show in the unified table (active layers first, then forecast-only keys)
    const forecastOnlyKeys = ['cwr', 'iwr'];
    final forecast = data.forecast as Map?;

    // Build the complete set of row keys:
    // start with active layers that have today data,
    // then add forecast-only keys not already present
    final allRowKeys = [...keysToShow];
    for (final fk in forecastOnlyKeys) {
      if (!allRowKeys.contains(fk)) {
        final byLayer = forecast?[fk];
        final hasForecastData =
            byLayer is Map && byLayer.values.any((v) => v != null);
        if (hasForecastData) allRowKeys.add(fk);
      }
    }

    // ── Unified table: LAYER | TODAY | 5 DAY | 10 DAY | 15 DAY ──
    const colWidths = [44.0, 62.0]; // label, today; forecast cols are Expanded

    Widget _headerCell(String text, {bool isTeal = false}) => Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isTeal ? AppTheme.brandTeal : headerColor,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header: date + close ──
        Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 11, color: AppTheme.brandTeal),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                displayDate ?? '—',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),
            ),
            _CloseBtn(onClose: onClose, isDark: isDark),
          ],
        ),
        const SizedBox(height: 8),

        if (allRowKeys.isEmpty)
          Text('No active layer',
              style: TextStyle(fontSize: 11, color: subColor))
        else ...[
          // ── Table header row ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            decoration: BoxDecoration(
              color: rowBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                SizedBox(
                    width: colWidths[0],
                    child: _headerCell('LAYER')),
                SizedBox(
                    width: colWidths[1],
                    child: Center(child: _headerCell('TODAY'))),
                ...forecastWindows.values.map(
                  (label) => Expanded(
                    child: Center(child: _headerCell(label, isTeal: true)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),

          // ── Data rows ──
          ...allRowKeys.asMap().entries.map((entry) {
            final key = entry.value;
            final isLast = entry.key == allRowKeys.length - 1;
            final rawVal = data.values[key];
            final double? todayVal =
                rawVal is num ? rawVal.toDouble() : null;
            final unit = _unitFor(key);
            final chip = _chipColor(key, todayVal);

            String _fmt(double? v) {
              if (v == null) return '—';
              return unit.isEmpty
                  ? v.toStringAsFixed(2)
                  : '${v.toStringAsFixed(1)} $unit';
            }

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 3),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: isLast
                        ? BorderSide.none
                        : BorderSide(color: dividerColor, width: 0.6),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Layer label
                    SizedBox(
                      width: colWidths[0],
                      child: Text(
                        key.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: subColor,
                        ),
                      ),
                    ),
                    // Today value chip
                    SizedBox(
                      width: colWidths[1],
                      child: Center(
                        child: todayVal == null
                            ? Text('—',
                                style: TextStyle(
                                    fontSize: 10, color: subColor))
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: chip,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  _fmt(todayVal),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _textOn(chip),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    // Forecast columns
                    ...forecastWindows.entries.map((win) {
                      final byLayer = forecast?[key];
                      double? fval;
                      if (byLayer is Map) {
                        final raw = byLayer[win.key];
                        if (raw is num) fval = raw.toDouble();
                      }
                      return Expanded(
                        child: Center(
                          child: Text(
                            _fmt(fval),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              color: fval == null
                                  ? headerColor
                                  : (isDark
                                      ? AppTheme.brandTeal
                                      : const Color(0xFF006064)),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  String _unitFor(String key) {
    switch (key) {
      case 'etc':
      case 'cwr':
      case 'iwr':
        return 'mm';
      default:
        return '';
    }
  }

  Color _chipColor(String key, double? value) {
    if (value == null) return Colors.grey.shade700;
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

class _CloseBtn extends StatelessWidget {
  final VoidCallback onClose;
  final bool isDark;
  const _CloseBtn({required this.onClose, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.close,
          size: 13,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
    );
  }
}
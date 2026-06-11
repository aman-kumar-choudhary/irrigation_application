import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _aboutKey = GlobalKey();
  final _regionKey = GlobalKey();
  late final AnimationController _motionController;

  static const _darkBgPrimary = Color(0xFF040814);
  static const _darkBgSecondary = Color(0xFF0A1128);
  static const _darkTextPrimary = Color(0xFFF8FAFC);
  static const _darkTextSecondary = Color(0xFF94A3B8);
  static const _darkTextMuted = Color(0xFF64748B);
  static const _accentTeal = Color(0xFF00D4A8);
  static const _accentTealSoft = Color(0xFF70FFE3);
  static const _accentAmber = Color(0xFFFDE047);

  static const _lightBgPrimary = Color(0xFFF8FAFC);
  static const _lightBgSecondary = Color(0xFFF1F5F9);
  static const _lightTextPrimary = Color(0xFF0F172A);
  static const _lightTextMuted = Color(0xFF64748B);
  static const _lightAccentTeal = Color(0xFF0D9488);
  static const _lightAccentAmber = Color(0xFFD97706);

  static const List<_StudyCardData> _studyCards = [
    _StudyCardData(
      icon: 'SR',
      signal: 'Terai GIS',
      title: 'Study Region',
      text:
          'Canal-fed wheat belt with field boundaries, terrain context and seasonal crop masks.',
    ),
    _StudyCardData(
      icon: 'CM',
      signal: 'NDVI / LAI',
      title: 'Crop Monitoring',
      text:
          'Growth stage intelligence from vegetation indices and in-season field observations.',
    ),
    _StudyCardData(
      icon: 'ET',
      signal: 'Flux Tower',
      title: 'ET Tower Data',
      text:
          'Ground evapotranspiration measurements for calibration of crop water requirement maps.',
    ),
    _StudyCardData(
      icon: 'SO',
      signal: 'Satellite Stack',
      title: 'Satellite Observation',
      text:
          'Multi-date remote sensing layers aligned with irrigation demand and crop vigor.',
    ),
    _StudyCardData(
      icon: 'RA',
      signal: 'Rainfall Grid',
      title: 'Rainfall Analysis',
      text:
          'Rainfall variability tracked against field water stress and irrigation windows.',
    ),
    _StudyCardData(
      icon: 'WO',
      signal: 'Decision Layer',
      title: 'Water Optimization',
      text:
          'Spatial recommendations to reduce waste while keeping wheat productivity stable.',
    ),
  ];

  
 

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _motionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Color _textPrimary(bool isDark) =>
      isDark ? _darkTextPrimary : _lightTextPrimary;

  Color _textMuted(bool isDark) => isDark ? _darkTextMuted : _lightTextMuted;

  Color _teal(bool isDark) => isDark ? _accentTeal : _lightAccentTeal;

  void _showSection(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;

    return Scaffold(
      backgroundColor: isDark ? _darkBgPrimary : _lightBgPrimary,
      body: Stack(
        children: [
          Positioned.fill(
            child: _AnimatedHomeBackground(
              controller: _motionController,
              isDark: isDark,
            ),
          ),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _governmentHeader(context, isDark)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedHeaderDelegate(
                  height: 64,
                  child: _homeNav(provider, isDark),
                ),
              ),
              SliverToBoxAdapter(child: _statusStrip(isDark)),
              SliverToBoxAdapter(child: _hero(context, provider, isDark)),
              SliverToBoxAdapter(child: _regionSection(context, isDark)),
              SliverToBoxAdapter(child: _statsSection(context, isDark)),
              SliverToBoxAdapter(child: _footer(context, isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _governmentHeader(BuildContext context, bool isDark) {
    final headerBg = isDark ? const Color(0xFF1A4A6B) : _lightBgPrimary;
    final headerText = isDark ? Colors.white : _lightTextPrimary;

    return Container(
      color: headerBg,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 768;
            final tiny = constraints.maxWidth < 430;
            final logoHeight = tiny ? 40.0 : (compact ? 55.0 : 64.0);
            final horizontalPadding = compact ? 16.0 : 24.0;
            final title = _headerTitle(headerText, compact);

            final leftLogos = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _logo(
                  'assets/images/logo.png',
                  'IIRS',
                  logoHeight,
                  maxWidth: logoHeight ,
                  isDark: isDark,
                ),
                SizedBox(width: tiny ? 10 : 16),
                _logo(
                  'assets/images/isro.png',
                  'ISRO',
                  logoHeight,
                  maxWidth: logoHeight ,
                  isDark: isDark,
                ),
              ],
            );

            final rightLogos = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _logo(
                  'assets/images/iirs.png',
                  'IIRS',
                  logoHeight,
                  isDark: isDark,
                ),
                SizedBox(width: tiny ? 10 : 16),
                _logo(
                  'assets/images/india.png',
                  'India',
                  logoHeight,
                  isDark: isDark,
                ),
              ],
            );

            return DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.black.withOpacity(0.18)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      14,
                      horizontalPadding,
                      compact ? 14 : 16,
                    ),
                    child: compact
                        ? Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(child: leftLogos),
                                  const SizedBox(width: 12),
                                  Flexible(child: rightLogos),
                                ],
                              ),
                              const SizedBox(height: 10),
                              title,
                            ],
                          )
                        : Row(
                            children: [
                              leftLogos,
                              Expanded(child: title),
                              rightLogos,
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _headerTitle(Color color, bool compact) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'भारतीय अंतरिक्ष अनुसंधान संगठन, अंतरिक्ष विभाग',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansDevanagari(
              color: color,
              fontSize: compact ? 17 : 23,
              fontWeight: FontWeight.w800,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Indian Space Research Organisation, Department of Space',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: color,
              fontSize: compact ? 15 : 18,
              fontWeight: FontWeight.w500,
              height: 1.22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'भारत सरकार / Government of India',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: color,
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w400,
              height: 1.24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _homeNav(AppProvider provider, bool isDark) {
    final bg = isDark ? const Color(0xFF009688) : Colors.white;
    final textColor = isDark ? Colors.white : _lightAccentTeal;

    return Material(
      color: bg,
      elevation: 4,
      shadowColor: Colors.black,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.black.withOpacity(0.15), width: 2),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 560;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: compact ? null : constraints.maxWidth,
                    height: 64,
                    child: Row(
                      mainAxisSize:
                          compact ? MainAxisSize.min : MainAxisSize.max,
                      mainAxisAlignment: compact
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        SizedBox(width: compact ? 4 : 0),
                        _navLink(
                          'About',
                          textColor,
                          () => _showSection(_aboutKey),
                        ),
                        _navLink(
                          'Study Region',
                          textColor,
                          () => _showSection(_regionKey),
                        ),
                        _navLink(
                          'Docs',
                          textColor,
                          () => provider.setIndex(3),
                        ),
                        _navLink(
                          'FAQs',
                          textColor,
                          () => provider.setIndex(4),
                        ),
                        SizedBox(width: compact ? 4 : 0),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusStrip(bool isDark) {
    final teal = _teal(isDark);
    return Container(
      color: teal.withOpacity(isDark ? 0.15 : 0.18),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: teal,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: teal.withOpacity(0.75),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE',
                style: GoogleFonts.jetBrainsMono(
                  color: teal,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, AppProvider provider, bool isDark) {
    final size = MediaQuery.sizeOf(context);
    final isPhone = size.width < 560;
    final isTablet = size.width < 920;
    final heroHeight = isPhone
        ? math.max(500.0, math.min(size.height * 0.74, 600.0))
        : math.max(560.0, math.min(size.height - 170, 760.0));
    final titleSize = isPhone ? 44.0 : (isTablet ? 64.0 : 82.0);
    final subtitleSize = isPhone ? 14.0 : (isTablet ? 19.0 : 23.0);

    return SizedBox(
      key: _aboutKey,
      height: heroHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/BG.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => Container(
                color: isDark ? _darkBgSecondary : _lightBgSecondary,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xE00A0F1C),
                          const Color(0xB30A0F1C),
                          const Color(0xD90A0F1C),
                        ]
                      : [
                          const Color(0xB3F8FAFC),
                          const Color(0x66F8FAFC),
                          const Color(0x99F8FAFC),
                        ],
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isPhone ? 18 : 24,
                  72,
                  isPhone ? 18 : 24,
                  90,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _heroBadge(isDark, isPhone),
                    const SizedBox(height: 24),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.outfit(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          height: 1.03,
                          color: _textPrimary(isDark),
                          shadows: isDark
                              ? [
                                  const Shadow(
                                    color: Color(0x99000000),
                                    blurRadius: 24,
                                    offset: Offset(0, 4),
                                  ),
                                  Shadow(
                                    color: _accentTeal.withOpacity(0.25),
                                    blurRadius: 60,
                                  ),
                                ]
                              : [
                                  const Shadow(
                                    color: Color(0xCCFFFFFF),
                                    blurRadius: 20,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                        ),
                        children: [
                          const TextSpan(text: 'JAL'),
                          TextSpan(
                            text: 'DRISHTI',
                            style: TextStyle(color: _teal(isDark)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Crop Irrigation water requirements',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: isDark ? _accentAmber : _lightAccentAmber,
                        letterSpacing: 0,
                        shadows: isDark
                            ? const [
                                Shadow(
                                  color: Color(0x99000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : const [
                                Shadow(
                                  color: Color(0xCCFFFFFF),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Rabi wheat crop',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: isPhone ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: _teal(isDark),
                        height: 1.8,
                        shadows: isDark
                            ? const [
                                Shadow(
                                  color: Color(0x99000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 34),
                    _mapButton(provider, isDark),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroBadge(bool isDark, bool isPhone) {
    final teal = _teal(isDark);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 14 : 20,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0x660A0F1C)
            : Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: teal.withOpacity(0.30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.10 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: teal,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: teal.withOpacity(0.65), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isPhone
                  ? 'Rabi Season Active · Udham Singh Nagar'
                  : 'Rabi Season Active · Udham Singh Nagar, Uttarakhand',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                fontSize: isPhone ? 10 : 12,
                fontWeight: FontWeight.w700,
                color: teal,
                letterSpacing: 0,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapButton(AppProvider provider, bool isDark) {
    return OutlinedButton.icon(
      onPressed: () => provider.setIndex(1),
      icon: const Icon(Icons.arrow_forward, size: 18),
      label: const Text('Open Map'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _textPrimary(isDark),
        backgroundColor:
            isDark ? const Color(0x661E293B) : Colors.white.withOpacity(0.90),
        side: BorderSide(
          color: isDark
              ? _accentTeal.withOpacity(0.30)
              : _lightAccentTeal.withOpacity(0.30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _regionSection(BuildContext context, bool isDark) {
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < 560;
    final tablet = width < 1100;
    final padding = EdgeInsets.symmetric(
      horizontal: phone ? 16 : 24,
      vertical: phone ? 72 : 96,
    );

    return Container(
      key: _regionKey,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF030711),
            Color(0xFF071323),
            Color(0xFF071D1C),
          ],
          stops: [0, 0.46, 1],
        ),
        border: Border(
          top: BorderSide(color: Color(0x1F00D4A8)),
          bottom: BorderSide(color: Color(0x1F00D4A8)),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RegionGridPainter(),
            ),
          ),
          Padding(
            padding: padding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1220),
                child: Column(
                  children: [
                    _regionHeader(phone),
                    SizedBox(height: phone ? 30 : 44),
                    tablet
                        ? Column(
                            children: [
                              _regionVisualCard(
                                phone: phone,
                                height: phone ? 430 : 500,
                              ),
                              const SizedBox(height: 24),
                              _studyCardGrid(),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 108,
                                child: _regionVisualCard(
                                  phone: false,
                                  height: 620,
                                ),
                              ),
                              const SizedBox(width: 28),
                              Expanded(flex: 92, child: _studyCardGrid()),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _regionHeader(bool phone) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Column(
        children: [
          _sectionTag('Study Region'),
          const SizedBox(height: 20),
          Text(
            'Futuristic GIS Irrigation Intelligence',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: phone ? 32 : 44,
              fontWeight: FontWeight.w800,
              color: _darkTextPrimary,
              height: 1.14,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Udham Singh Nagar Rabi wheat fields monitored through satellite layers, ET tower telemetry, rainfall signals and crop water demand analytics.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: phone ? 15 : 17,
              height: 1.75,
              color: const Color(0xFFA8B8C9),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _regionVisualCard({required bool phone, required double height}) {
    final radius = BorderRadius.circular(phone ? 22 : 28);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xB8081221),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.42),
            blurRadius: 70,
            offset: const Offset(0, 26),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: _accentTealSoft.withOpacity(0.24)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/towercrop.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF081221)),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x05030711),
                    Color(0x75030711),
                    Color(0xEF030711),
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x2E00D4A8), Colors.transparent],
                  begin: Alignment.centerLeft,
                  end: Alignment.center,
                ),
              ),
            ),
            _RegionScanline(controller: _motionController),
            Positioned(
              left: phone ? 18 : 28,
              right: phone ? 18 : 28,
              bottom: phone ? 18 : 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _regionKicker(),
                  const SizedBox(height: 18),
                  Text(
                    'Udham Singh Nagar, Uttarakhand',
                    style: GoogleFonts.outfit(
                      fontSize: phone ? 32 : 50,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                      shadows: const [
                        Shadow(
                          color: Color(0x8C000000),
                          blurRadius: 34,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _regionKicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x8F030711),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _accentTealSoft.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _accentTeal,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _accentTeal.withOpacity(0.90),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Field Network Online',
            style: GoogleFonts.jetBrainsMono(
              color: _accentTealSoft,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

 

  Widget _metricTile(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xA8050D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.jetBrainsMono(
              color: _accentTealSoft,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFFC7D2DE),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _studyCardGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 430;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _studyCards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: twoColumns ? 2 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: twoColumns ? 190 : 172,
          ),
          itemBuilder: (context, index) => _studyCard(_studyCards[index]),
        );
      },
    );
  }

  Widget _studyCard(_StudyCardData card) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xC70F1D31), Color(0x85081221)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x2494A3B8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -24,
            top: -24,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentTeal.withOpacity(0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _accentTeal.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _accentTeal.withOpacity(0.22)),
                    ),
                    child: Text(
                      card.icon,
                      style: GoogleFonts.jetBrainsMono(
                        color: _accentTealSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      card.signal,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFF8AA0B5),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                card.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: _darkTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                card.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF98AABE),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsSection(BuildContext context, bool isDark) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 1024 ? 6 : (width >= 640 ? 3 : 2);
    final surface = isDark ? const Color(0x66131E3A) : Colors.white;
    final border = isDark
        ? _accentTeal.withOpacity(0.15)
        : Colors.black.withOpacity(0.08);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          top: BorderSide(color: border),
          bottom: BorderSide(color: border),
        ),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisExtent: 142,
        ),
        itemBuilder: (context, index) {
         
        },
      ),
    );
  }

  Widget _overviewStatCard(
    _StatData stat,
    bool isDark, {
    required bool showRightBorder,
  }) {
    final teal = _teal(isDark);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: showRightBorder
              ? BorderSide(
                  color: isDark
                      ? _accentTeal.withOpacity(0.15)
                      : Colors.black.withOpacity(0.08),
                )
              : BorderSide.none,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(stat.icon, color: teal, size: 29),
          const SizedBox(height: 10),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.jetBrainsMono(
              color: teal,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              height: 1,
              shadows: isDark
                  ? [Shadow(color: teal.withOpacity(0.35), blurRadius: 15)]
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              stat.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: _textMuted(isDark),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, bool isDark) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    final footerBg = isDark ? const Color(0xFF070808) : const Color(0xFF0B1827);

    final brand = Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          '· Irrigation Water Requirements',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.outfit(
            color: _darkTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'ISRO · IIRS · Department of Space, Govt. of India',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.inter(
            color: _darkTextMuted,
            fontSize: 13,
            height: 1.35,
          ),
        ),
        Text(
          'Udham Singh Nagar · Uttarakhand · Rabi Wheat',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.inter(
            color: _darkTextMuted,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ],
    );

    return Container(
      color: footerBg,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: compact
              ? Column(
                  children: [
                    brand,
                    const SizedBox(height: 24),
                    const SizedBox(height: 20),
                  
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: brand),
                  ],
                ),
        ),
      ),
    );
  }

  

  Widget _logo(
    String asset,
    String fallback,
    double height, {
    double? maxWidth,
    required bool isDark,
  }) {
    final width = maxWidth ?? height;
    return SizedBox(
      height: height,
      width: width,
      child: Image.asset(
        asset,
        height: height,
        width: width,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isDark ? 0.14 : 0.55),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.20 : 0.45),
            ),
          ),
          child: Text(
            fallback,
            style: TextStyle(
              color: isDark ? Colors.white : _lightTextPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _navLink(String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (states) => states.contains(MaterialState.hovered) ||
                    states.contains(MaterialState.pressed)
                ? Colors.white.withOpacity(0.18)
                : null,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _sectionTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _accentTeal.withOpacity(0.10),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _accentTeal.withOpacity(0.28)),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          color: _accentTealSoft,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _StudyCardData {
  final String icon;
  final String signal;
  final String title;
  final String text;

  const _StudyCardData({
    required this.icon,
    required this.signal,
    required this.title,
    required this.text,
  });
}

class _StatData {
  final IconData icon;
  final String value;
  final String label;

  const _StatData(this.icon, this.value, this.label);
}

class _FooterTechData {
  final String name;
  final String role;

  const _FooterTechData(this.name, this.role);
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  const _PinnedHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _AnimatedHomeBackground extends StatelessWidget {
  final AnimationController controller;
  final bool isDark;

  const _AnimatedHomeBackground({
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _HomeBackgroundPainter(
            progress: controller.value,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _HomeBackgroundPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  static const List<_ParticleSeed> _particles = [
    _ParticleSeed(0.07, 0.18, 2.5, 0.12, 0.12),
    _ParticleSeed(0.15, 0.62, 4.2, 0.20, 0.40),
    _ParticleSeed(0.24, 0.34, 3.4, 0.18, 0.70),
    _ParticleSeed(0.36, 0.78, 5.0, 0.14, 0.18),
    _ParticleSeed(0.46, 0.20, 2.2, 0.22, 0.52),
    _ParticleSeed(0.56, 0.50, 3.8, 0.16, 0.82),
    _ParticleSeed(0.66, 0.28, 3.0, 0.18, 0.28),
    _ParticleSeed(0.75, 0.70, 4.8, 0.12, 0.58),
    _ParticleSeed(0.84, 0.44, 2.8, 0.20, 0.88),
    _ParticleSeed(0.92, 0.16, 4.0, 0.16, 0.34),
    _ParticleSeed(0.11, 0.86, 3.1, 0.15, 0.76),
    _ParticleSeed(0.31, 0.10, 2.6, 0.13, 0.46),
    _ParticleSeed(0.51, 0.90, 4.4, 0.18, 0.08),
    _ParticleSeed(0.71, 0.08, 2.4, 0.14, 0.64),
    _ParticleSeed(0.89, 0.82, 3.5, 0.19, 0.24),
    _ParticleSeed(0.43, 0.58, 2.9, 0.20, 0.94),
    _ParticleSeed(0.63, 0.38, 4.6, 0.11, 0.50),
    _ParticleSeed(0.20, 0.48, 2.1, 0.21, 0.02),
  ];

  const _HomeBackgroundPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xFF040814), Color(0xFF0A1128)]
            : const [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final gridPaint = Paint()
      ..color =
          (isDark ? const Color(0xFF00D4A8) : const Color(0xFF0D9488))
              .withOpacity(isDark ? 0.05 : 0.07)
      ..strokeWidth = 1;
    const spacing = 60.0;
    final dy = progress * spacing;

    for (double x = -spacing; x <= size.width + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x, size.height * 0.08),
        Offset(x - size.width * 0.18, size.height),
        gridPaint,
      );
    }
    for (double y = -spacing; y <= size.height + spacing; y += spacing) {
      final lineY = y + dy;
      canvas.drawLine(
        Offset(0, lineY),
        Offset(size.width, lineY - size.height * 0.16),
        gridPaint,
      );
    }

    final ringCenter = Offset(size.width * 0.5, size.height * 0.5);
    _drawRing(canvas, ringCenter, math.min(size.width, size.height) * 0.34,
        const Color(0xFF00D4A8).withOpacity(0.11), progress);
    _drawRing(canvas, ringCenter, math.min(size.width, size.height) * 0.46,
        const Color(0xFF3B82F6).withOpacity(0.10), -progress * 0.78);

    final particlePaint = Paint();
    for (final particle in _particles) {
      final travel = (progress + particle.phase) % 1;
      final y = ((particle.y - travel * 0.75) % 1) * size.height;
      final opacity = particle.opacity * (1 - (travel - 0.5).abs() * 0.85);
      particlePaint.color = (isDark ? const Color(0xFF00D4A8) : _lightTeal)
          .withOpacity(opacity.clamp(0.02, 0.28).toDouble());
      canvas.drawCircle(
        Offset(particle.x * size.width, y),
        particle.size,
        particlePaint,
      );
    }
  }

  static const _lightTeal = Color(0xFF0D9488);

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double turn,
  ) {
    if (radius <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    canvas.drawCircle(center, radius, paint);

    final angle = turn * math.pi * 2 - math.pi / 2;
    final dot = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
    canvas.drawCircle(
      dot,
      5,
      Paint()
        ..color = color.withOpacity(0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(covariant _HomeBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}

class _ParticleSeed {
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double phase;

  const _ParticleSeed(this.x, this.y, this.size, this.opacity, this.phase);
}

class _RegionGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4A8).withOpacity(0.055)
      ..strokeWidth = 1;
    const spacing = 44.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RegionScanline extends StatelessWidget {
  final AnimationController controller;

  const _RegionScanline({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final wave = (math.sin(controller.value * math.pi * 2) + 1) / 2;
        return Positioned(
          left: 0,
          right: 0,
          top: -120 + wave * 520,
          height: 180,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _HomeScreenState._accentTealSoft.withOpacity(0.13),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

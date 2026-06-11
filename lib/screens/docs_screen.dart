import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class DocsScreen extends StatefulWidget {
  const DocsScreen({super.key});

  @override
  State<DocsScreen> createState() => _DocsScreenState();
}

class _DocsScreenState extends State<DocsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // Color constants matching home_screen
  static const _darkBgPrimary = Color(0xFF040814);
  static const _darkBgSecondary = Color(0xFF0A1128);
  static const _darkTextPrimary = Color(0xFFF8FAFC);
  // ignore: unused_field
  static const _darkTextSecondary = Color(0xFF94A3B8);
  static const _darkTextMuted = Color(0xFF64748B);
  static const _accentTeal = Color(0xFF00D4A8);

  static const _lightBgPrimary = Color(0xFFF8FAFC);
  static const _lightBgSecondary = Color(0xFFF1F5F9);
  static const _lightTextPrimary = Color(0xFF0F172A);
  static const _lightTextMuted = Color(0xFF64748B);
  static const _lightAccentTeal = Color(0xFF0D9488);

  static const List<_DocBlock> _blocks = [
    _DocBlock(
      title: 'Introduction',
      paragraphs: [
        'JalDrishti is an intelligent irrigation monitoring platform that helps users understand how much water a crop needs and when irrigation may be required.',
        'The name combines Jal, meaning water, and Drishti, meaning vision or insight. Together, JalDrishti means a vision for smart water management.',
      ],
    ),
    _DocBlock(
      title: 'What JalDrishti Does',
      paragraphs: [
        'The system studies field conditions, weather information, and satellite-based crop indicators, then presents the results through maps, charts, and simple values.',
      ],
      points: [
        'Monitors irrigation conditions across agricultural areas.',
        'Estimates Crop Water Requirement, also called CWR.',
        'Shows map layers that help compare different parts of a region.',
        'Creates pixel-level graphs for a selected location.',
        'Supports water conservation and precision agriculture.',
      ],
    ),
    _DocBlock(
      title: 'Why It Is Useful',
      paragraphs: [
        'Crops do not need the same amount of water every day. Rainfall, crop stage, temperature, and crop health all change irrigation demand.',
        'JalDrishti reduces guesswork by showing where water demand is high or low.',
      ],
    ),
    _DocBlock(
      title: 'Crop Water Requirement',
      paragraphs: [
        'CWR is the total amount of water a crop needs for healthy growth. IWR is the water that must be supplied through irrigation after considering rainfall and available moisture.',
      ],
      points: [
        'Evapotranspiration shows water loss from soil and plants.',
        'Vegetation indices indicate crop greenness and activity.',
        'Weather conditions affect daily water demand.',
        'Crop coefficient, or Kc, adjusts demand by growth stage.',
      ],
    ),
    _DocBlock(
      title: 'Interactive Geospatial Dashboard',
      paragraphs: [
        'The dashboard provides a map-based view of agricultural areas. Users can view raster layers, explore irrigation zones, inspect crop condition, and compare water requirement across fields.',
      ],
    ),
    _DocBlock(
      title: 'Raster Layers Explained',
      paragraphs: [
        'Raster data divides the map into many cells or pixels. Each pixel stores a value such as crop health, evapotranspiration, or irrigation requirement.',
      ],
      points: [
        'SAVI and NDVI indicate vegetation condition.',
        'Kc represents crop growth stage and water-use behavior.',
        'ETc shows crop water use.',
        'CWR shows water needed by the crop.',
        'IWR shows water that may need to be supplied.',
      ],
    ),
    _DocBlock(
      title: 'Pixel-Level Analytics',
      paragraphs: [
        'A user can click a point on the map to study values for that location. This supports local analysis for farmers, researchers, and irrigation planners.',
      ],
    ),
    _DocBlock(
      title: 'Time-Series Graphs',
      paragraphs: [
        'Time-series graphs show how crop and irrigation values change through the season. They make trends easier to understand than raw numbers.',
      ],
    ),
    _DocBlock(
      title: 'System Architecture',
      paragraphs: [
        'The platform follows a layered structure: data collection, processing, storage, and display through maps, charts, and dashboard tools.',
      ],
    ),
    _DocBlock(
      title: 'Applications',
      paragraphs: [
        'JalDrishti can support precision agriculture, smart irrigation planning, agricultural research, water resource management, crop monitoring, and drought assessment.',
      ],
    ),
    _DocBlock(
      title: 'Benefits',
      paragraphs: [
        'The main benefit is better decision-making. The platform helps users understand when irrigation is needed, where demand is higher, and how crop conditions are changing.',
      ],
    ),
    _DocBlock(
      title: 'Future Enhancements',
      paragraphs: [
        'Future development can add AI-based irrigation prediction, real-time sensor data, automated drought alerts, richer weather forecast integration, and mobile advisory workflows.',
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _textPrimary(bool isDark) =>
      isDark ? _darkTextPrimary : _lightTextPrimary;

  Color _textMuted(bool isDark) => isDark ? _darkTextMuted : _lightTextMuted;

  Color _teal(bool isDark) => isDark ? _accentTeal : _lightAccentTeal;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;
    final filtered = _filteredBlocks;

    return Scaffold(
      backgroundColor: isDark ? _darkBgPrimary : _lightBgPrimary,
      body: CustomScrollView(
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
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? _darkBgSecondary : _lightBgSecondary,
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 34),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _searchBox(isDark),
                      if (_query.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Showing ${filtered.length} matching topic${filtered.length == 1 ? '' : 's'} for "$_query".',
                          style: TextStyle(
                            fontSize: 12,
                            color: _textMuted(isDark),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _factBox(isDark),
                      const SizedBox(height: 26),
                      if (filtered.isEmpty)
                        _emptyState(isDark)
                      else
                        for (final block in filtered)
                          _articleBlock(block, isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _footer(context, isDark)),
        ],
      ),
    );
  }

  List<_DocBlock> get _filteredBlocks {
    final term = _query.trim().toLowerCase();
    if (term.isEmpty) return _blocks;
    return _blocks.where((block) {
      final text = [
        block.title,
        ...block.paragraphs,
        ...block.points,
      ].join(' ').toLowerCase();
      return text.contains(term);
    }).toList();
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
                  maxWidth: logoHeight,
                  isDark: isDark,
                ),
                SizedBox(width: tiny ? 10 : 16),
                _logo(
                  'assets/images/isro.png',
                  'ISRO',
                  logoHeight,
                  maxWidth: logoHeight,
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
                          () => provider.setIndex(0),
                        ),
                        _navLink(
                          'Study Region',
                          textColor,
                          () => provider.setIndex(0),
                        ),
                        _navLink(
                          'Docs',
                          textColor,
                          () => provider.setIndex(3),
                          active: true,
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

  Widget _searchBox(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1128) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2A3A) : const Color(0xFFCBD5E1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Text(
            'Search',
            style: GoogleFonts.jetBrainsMono(
              color: _teal(isDark),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search this',
                hintStyle: TextStyle(
                  color: _textMuted(isDark),
                ),
              ),
              style: TextStyle(
                color: _textPrimary(isDark),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              style: TextButton.styleFrom(
                foregroundColor: _teal(isDark),
              ),
              child: const Text('Clear'),
            ),
        ],
      ),
    );
  }

  Widget _factBox(bool isDark) {
    const rows = [
      ('Purpose', 'Smart irrigation planning'),
      ('Focus crop', 'Rabi wheat'),
      ('Study area', 'Udham Singh Nagar'),
      ('Main outputs', 'CWR, IWR, SAVI, NDVI, Kc, ETc'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1128) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2A3A) : const Color(0xFFCBD5E1),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Image.asset(
            'assets/images/about.png',
            height: 170,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 170,
              color: isDark ? const Color(0xFF1A2A4A) : Colors.grey.shade200,
              child: const Icon(Icons.image_not_supported),
            ),
          ),
          for (final row in rows)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 108,
                    child: Text(
                      row.$1,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _textMuted(isDark),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: TextStyle(
                        color: _textMuted(isDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _articleBlock(_DocBlock block, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 7),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF1E2A3A) : const Color(0xFFD7DEE8),
                ),
              ),
            ),
            child: Text(
              block.title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _textPrimary(isDark),
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final paragraph in block.paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                paragraph,
                style: TextStyle(
                  height: 1.72,
                  color: _textMuted(isDark),
                ),
              ),
            ),
          if (block.points.isNotEmpty)
            ...block.points.map(
              (point) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '- ',
                      style: TextStyle(
                        color: _textMuted(isDark),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          height: 1.55,
                          color: _textMuted(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1128) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2A3A) : const Color(0xFFCBD5E1),
          style: BorderStyle.solid,
        ),
      ),
      child: Text(
        'No matching content found. Try water, crop, map, graph, farmer, or satellite.',
        style: TextStyle(
          color: _textMuted(isDark),
        ),
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

  Widget _navLink(String label, Color color, VoidCallback onTap, {bool active = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: color,
          backgroundColor: active ? Colors.white.withOpacity(0.18) : null,
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
}

class _DocBlock {
  final String title;
  final List<String> paragraphs;
  final List<String> points;

  const _DocBlock({
    required this.title,
    required this.paragraphs,
    this.points = const [],
  });
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
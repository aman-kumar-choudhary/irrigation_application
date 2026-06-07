import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';

class DocsScreen extends StatefulWidget {
  const DocsScreen({super.key});

  @override
  State<DocsScreen> createState() => _DocsScreenState();
}

class _DocsScreenState extends State<DocsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;
    final filtered = _filteredBlocks;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _governmentHeader(isDark)),
          SliverToBoxAdapter(child: _pageNav(provider)),
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF07111E) : Colors.white,
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
                            color: isDark
                                ? AppTheme.darkTextMuted
                                : AppTheme.lightTextMuted,
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
          SliverToBoxAdapter(child: _footer(isDark)),
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

  Widget _governmentHeader(bool isDark) {
    return Container(
      color: const Color(0xFF1A4A6B),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _logo('assets/icons/logo1.png', 'IIRS', 42),
                      const SizedBox(width: 10),
                      _logo('assets/icons/isro.png', 'ISRO', 42),
                    ],
                  ),
                  Row(
                    children: [
                      _logo('assets/icons/iirs.png', 'IIRS', 42),
                      const SizedBox(width: 10),
                      _logo('assets/icons/india.png', 'India', 42),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Indian Space Research Organisation, Department of Space',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Government of India',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageNav(AppProvider provider) {
    return Container(
      height: 48,
      color: const Color(0xFF009688),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        children: [
          _navButton('Home', () => provider.setIndex(0)),
          _navButton('Docs', () => provider.setIndex(3), active: true),
          _navButton('FAQs', () => provider.setIndex(4)),
          _navButton('Open Map', () => provider.setIndex(1)),
        ],
      ),
    );
  }

  Widget _searchBox(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Text(
            'Search',
            style: GoogleFonts.jetBrainsMono(
              color: isDark ? AppTheme.brandTeal : AppTheme.brandPrimary,
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
                  color:
                      isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                ),
              ),
              style: TextStyle(
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
          ),
          if (_query.isNotEmpty)
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
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
        color: isDark ? AppTheme.darkSurface2 : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1),
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
              color: isDark ? AppTheme.darkSurface3 : Colors.grey.shade200,
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
                        color: isDark
                            ? AppTheme.darkTextSoft
                            : AppTheme.lightTextSoft,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextMuted
                            : AppTheme.lightTextMuted,
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
                  color: isDark ? AppTheme.darkBorder : const Color(0xFFD7DEE8),
                ),
              ),
            ),
            child: Text(
              block.title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
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
                  color:
                      isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
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
                        color: isDark
                            ? AppTheme.darkTextSoft
                            : AppTheme.lightTextSoft,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          height: 1.55,
                          color: isDark
                              ? AppTheme.darkTextSoft
                              : AppTheme.lightTextSoft,
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
        color: isDark ? AppTheme.darkSurface2 : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1),
          style: BorderStyle.solid,
        ),
      ),
      child: Text(
        'No matching content found. Try water, crop, map, graph, farmer, or satellite.',
        style: TextStyle(
          color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
        ),
      ),
    );
  }

  Widget _footer(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: isDark ? const Color(0xFF070D12) : const Color(0xFFF8FAFC),
      child: Text(
        'JalDrishti - Irrigation Water Requirements\nISRO - IIRS - Department of Space, Government of India',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          height: 1.55,
          color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
        ),
      ),
    );
  }

  Widget _logo(String asset, String fallback, double size) {
    return Image.asset(
      asset,
      height: size,
      width: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        height: size,
        width: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          fallback,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _navButton(String label, VoidCallback onTap, {bool active = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: active ? Colors.white.withOpacity(0.18) : null,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        child: Text(label.toUpperCase()),
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

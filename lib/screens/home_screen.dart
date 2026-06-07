import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  final _aboutKey = GlobalKey();
  final _regionKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showSection(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _governmentHeader(context, isDark)),
          SliverToBoxAdapter(child: _homeNav(provider)),
          SliverToBoxAdapter(child: _hero(context, provider, isDark)),
          SliverToBoxAdapter(child: _regionSection(context, isDark)),
          SliverToBoxAdapter(child: _statsSection(isDark)),
          SliverToBoxAdapter(child: _footer(isDark)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _governmentHeader(BuildContext context, bool isDark) {
    return Container(
      color: const Color(0xFF1A4A6B),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final title = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'भारतीय अंतरिक्ष अनुसंधान संगठन, अंतरिक्ष विभाग',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: compact ? 15 : 20,
                    fontWeight: FontWeight.w800,
                    height: 1.00,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Indian Space Research Organisation, Department of Space',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: compact ? 12 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'भारत सरकार / Government of India',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.74),
                    fontSize: compact ? 11 : 13,
                  ),
                ),
              ],
            );

            if (compact) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _logo('assets/icons/logo1.png', 'IIRS', 44),
                            const SizedBox(width: 12),
                            _logo('assets/icons/isro.png', 'ISRO', 44),
                          ],
                        ),
                        Row(
                          children: [
                            _logo('assets/icons/iirs.png', 'IIRS', 44),
                            const SizedBox(width: 12),
                            _logo('assets/icons/india.png', 'India', 44),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    title,
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
              child: Row(
                children: [
                  _logo('assets/icons/logo1.png', 'IIRS', 64),
                  const SizedBox(width: 16),
                  _logo('assets/icons/isro.png', 'ISRO', 64),
                  Expanded(child: title),
                  _logo('assets/icons/iirs.png', 'IIRS', 64),
                  const SizedBox(width: 16),
                  _logo('assets/icons/india.png', 'India', 58),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _homeNav(AppProvider provider) {
    return Container(
      height: 44,
      color: const Color(0xFF009688),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 8),
        children: [
          _navPill('About', Icons.info_outline, () => _showSection(_aboutKey)),
          _navPill('Study Region', Icons.terrain_outlined,
              () => _showSection(_regionKey)),
          _navPill('Docs', Icons.article_outlined, () => provider.setIndex(3)),
          _navPill('FAQs', Icons.help_outline, () => provider.setIndex(4)),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, AppProvider provider, bool isDark) {
    final height = MediaQuery.of(context).size.height;

    return SizedBox(
      key: _aboutKey,
      height: height < 720 ? 480 : 560,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/BG.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => Container(
                color: isDark ? const Color(0xFF0B1827) : AppTheme.lightSurface,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xCC07111E)
                    : Colors.white.withOpacity(0.62),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 42, 24, 54),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.25)
                            : Colors.white.withOpacity(0.86),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: AppTheme.brandTeal.withOpacity(0.42),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.brandTeal,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Rabi Season Active · Udham Singh Nagar',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.brandTeal
                                  : AppTheme.brandPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'JALDRISHTI',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppTheme.lightText,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Irrigation water requirements',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFDE047),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Satellite-driven crop water monitoring for Rabi wheat in Udham Singh Nagar, Uttarakhand.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.6,
                        color: isDark
                            ? const Color(0xFFE5F2EF)
                            : AppTheme.lightTextSoft,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 220,
                      child: ElevatedButton.icon(
                        onPressed: () => provider.setIndex(1),
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('Open Map'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandTeal,
                          foregroundColor: const Color(0xFF042018),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
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

  Widget _regionSection(BuildContext context, bool isDark) {
    return Container(
      key: _regionKey,
      color: isDark ? const Color(0xFF102235) : const Color(0xFFF1F5F9),
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 36),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTag('Study Region', isDark),
              const SizedBox(height: 14),
              Text(
                'Rabi Wheat Belt\nUdham Singh Nagar',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'The system is applied to the Rabi wheat-growing region of Udham Singh Nagar in Uttarakhand. The area has fertile soils, high cropping intensity, and strong irrigation dependence during low-rainfall winter months.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.65,
                  color:
                      isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _tag('Uttarakhand, India', isDark),
                  _tag('Rabi Wheat', isDark),
                  _tag('Irrigation-Dependent', isDark),
                ],
              ),
            ],
          );

          final image = ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: compact ? 16 / 10 : 4 / 3,
              child: Image.asset(
                'assets/images/barley.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: isDark ? AppTheme.darkSurface3 : Colors.grey.shade200,
                  child:
                      const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
          );

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [text, const SizedBox(height: 22), image],
                    )
                  : Row(
                      children: [
                        Expanded(child: text),
                        const SizedBox(width: 32),
                        Expanded(child: image),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _footer(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 1),
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
      color: isDark ? const Color(0xFF070D12) : Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 1),
          Text(
            'Irrigation Water Requirements',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            'ISRO · IIRS · Department of Space, Govt. of India',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsSection(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF07111E) : AppTheme.lightSurface,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.55,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _statCard(Icons.grass_outlined, 'Rabi', 'Wheat season', isDark),
          _statCard(Icons.sensors_outlined, 'ET', 'Tower calibration', isDark),
          _statCard(Icons.public_outlined, 'GIS', 'Spatial monitoring', isDark),
          _statCard(Icons.water_drop_outlined, 'IWR', 'Water demand', isDark),
        ],
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
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Text(
          fallback,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _navPill(String label, IconData icon, VoidCallback onTap,
      {bool filled = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: TextButton.styleFrom(
          backgroundColor:
              filled ? Colors.white : Colors.white.withOpacity(0.12),
          foregroundColor: filled ? const Color(0xFF00695C) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _sectionTag(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.brandTeal.withOpacity(isDark ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.brandTeal.withOpacity(0.28)),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isDark ? AppTheme.brandTeal : AppTheme.brandPrimary,
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface2 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: isDark ? AppTheme.brandTeal : AppTheme.brandPrimary),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface3 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

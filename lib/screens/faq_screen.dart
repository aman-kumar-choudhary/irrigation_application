import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int? _openIndex;

  // Color constants matching home_screen
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

  static const List<_FaqItem> _faqs = [
    _FaqItem(
      question: 'What is JalDrishti?',
      answer:
          'JalDrishti is a smart water advisory system built for irrigation planning. It works like a weather app for crop water need, using satellite images and weather data to show how much water wheat fields may need.',
    ),
    _FaqItem(
      question: 'Who is this system for?',
      answer:
          'It is designed for farmers, irrigation officers, agricultural advisors, researchers, and water managers in the Udham Singh Nagar study region.',
    ),
    _FaqItem(
      question: 'Why was JalDrishti developed?',
      answer:
          'Many fields are irrigated by habit rather than measured demand. JalDrishti helps reduce over-irrigation, save groundwater, lower pumping cost, and keep crop growth stable.',
    ),
    _FaqItem(
      question: 'Which area does it cover?',
      answer:
          'The current implementation focuses on Udham Singh Nagar district in Uttarakhand, a major Rabi wheat-growing region in the Terai belt.',
    ),
    _FaqItem(
      question: 'What is Irrigation Water Requirement?',
      answer:
          'IWR is the amount of water that must be supplied through irrigation after accounting for rainfall and available moisture. In simple terms: crop water need minus useful rainfall equals irrigation water requirement.',
    ),
    _FaqItem(
      question: 'How much water does wheat need per day?',
      answer:
          'It changes with growth stage. Early wheat needs less water, active growth needs more, and ripening demand drops again. The map and chart tools help track this change through the season.',
    ),
    _FaqItem(
      question: 'How does the system know field water need?',
      answer:
          'It combines satellite-derived crop indicators, weather variables, crop coefficient estimates, evapotranspiration, and processed raster layers to estimate water demand.',
    ),
    _FaqItem(
      question: 'Which satellites does JalDrishti use?',
      answer:
          'The workflow uses satellite and weather inputs such as Sentinel-2 style crop observations and meteorological products that support evapotranspiration and crop-water calculations.',
    ),
    _FaqItem(
      question: 'What if clouds block satellite imagery?',
      answer:
          'When imagery is not available, the system can rely on the most recent usable observations and weather-driven estimates until a clearer observation is available.',
    ),
    _FaqItem(
      question: 'What layers can I view on the map?',
      answer:
          'The map supports SAVI, Kc, ETc, CWR, and IWR layers. Each layer has a legend so users can compare crop health, growth stage, water use, and irrigation demand.',
    ),
    _FaqItem(
      question: 'Can JalDrishti forecast water needs?',
      answer:
          'Yes. Forecast windows help users inspect likely crop-water conditions ahead of time, which is useful for planning irrigation and canal scheduling.',
    ),
    _FaqItem(
      question: 'Is there a cost to use JalDrishti?',
      answer:
          'The platform is a public-service research tool for farmers, researchers, and government agencies. Commercial use may require separate permissions from the project owners.',
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
    final filtered = _filteredFaqs;

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
          SliverToBoxAdapter(child: _hero(isDark, filtered.length)),
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? _darkBgSecondary : _lightBgSecondary,
              padding: const EdgeInsets.fromLTRB(12, 32, 12, 42),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: filtered.isEmpty
                      ? _emptyState(isDark)
                      : Column(
                          children: [
                            for (int i = 0; i < filtered.length; i++)
                              _faqCard(filtered[i], i, isDark),
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

  List<_FaqItem> get _filteredFaqs {
    final term = _query.trim().toLowerCase();
    if (term.isEmpty) return _faqs;
    return _faqs.where((item) {
      return item.question.toLowerCase().contains(term) ||
          item.answer.toLowerCase().contains(term);
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
                        ),
                        _navLink(
                          'FAQs',
                          textColor,
                          () => provider.setIndex(4),
                          active: true,
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

  Widget _hero(bool isDark, int count) {
    final heroColor = isDark ? _darkBgSecondary : _lightBgSecondary;
    return Container(
      color: heroColor,
      padding: const EdgeInsets.fromLTRB(18, 44, 18, 36),
      child: Column(
        children: [
          Text(
            'HELP CENTER',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _teal(isDark),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Frequently Asked Questions',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: _textPrimary(isDark),
              height: 1.08,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Got questions about JalDrishti? Here are simple answers with no technical background needed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.65,
              color: _textMuted(isDark),
            ),
          ),
          const SizedBox(height: 28),
          _searchBox(isDark),
          if (_query.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Showing $count result${count == 1 ? '' : 's'} for "$_query"',
              style: TextStyle(
                color: _teal(isDark),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _searchBox(bool isDark) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() {
          _query = value;
          _openIndex = null;
        }),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _query = '';
                      _openIndex = null;
                    });
                  },
                ),
          hintText: 'Search questions, e.g. irrigation, satellite, wheat',
          filled: true,
          fillColor: isDark ? const Color(0xFF131E3A) : Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide(
              color: _teal(isDark),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _faqCard(_FaqItem item, int filteredIndex, bool isDark) {
    final isOpen = _openIndex == filteredIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1128) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOpen
              ? _teal(isDark)
              : isDark
                  ? const Color(0xFF1E2A3A)
                  : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.05),
            blurRadius: isOpen ? 20 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(
              () => _openIndex = isOpen ? null : filteredIndex,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.question,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.45,
                        color: isOpen
                            ? _teal(isDark)
                            : _textPrimary(isDark),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isOpen ? '-' : '+',
                    style: TextStyle(
                      fontSize: 24,
                      color: isOpen ? _teal(isDark) : _textMuted(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFF1F5F9),
                  ),
                ),
              ),
              child: Text(
                item.answer,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.75,
                  color: _textMuted(isDark),
                ),
              ),
            ),
            crossFadeState:
                isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2A3A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        'No results for "$_query". Try a different keyword.',
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

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
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
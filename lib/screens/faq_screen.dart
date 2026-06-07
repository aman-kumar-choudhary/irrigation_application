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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;
    final filtered = _filteredFaqs;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _governmentHeader()),
          SliverToBoxAdapter(child: _pageNav(provider)),
          SliverToBoxAdapter(child: _hero(isDark, filtered.length)),
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF07111E) : Colors.white,
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
          SliverToBoxAdapter(child: _footer(isDark)),
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

  Widget _governmentHeader() {
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
          _navButton('Docs', () => provider.setIndex(3)),
          _navButton('FAQs', () => provider.setIndex(4), active: true),
          _navButton('Open Map', () => provider.setIndex(1)),
        ],
      ),
    );
  }

  Widget _hero(bool isDark, int count) {
    final heroColor =
        isDark ? const Color(0xFF0B1827) : const Color(0xFFF0FDF9);
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
              color: isDark ? AppTheme.brandTeal : const Color(0xFF0D9488),
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
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
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
              color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
            ),
          ),
          const SizedBox(height: 28),
          _searchBox(isDark),
          if (_query.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Showing $count result${count == 1 ? '' : 's'} for "$_query"',
              style: TextStyle(
                color: isDark ? AppTheme.brandTeal : const Color(0xFF0D9488),
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
          fillColor: isDark ? AppTheme.darkSurface2 : Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide(
              color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1),
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide(
              color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1),
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide(
              color: isDark ? AppTheme.brandTeal : const Color(0xFF0D9488),
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
        color: isDark ? AppTheme.darkSurface2 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOpen
              ? (isDark ? AppTheme.brandTeal : const Color(0xFF0D9488))
              : isDark
                  ? AppTheme.darkBorder
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
                            ? (isDark
                                ? AppTheme.brandTeal
                                : const Color(0xFF0D9488))
                            : isDark
                                ? AppTheme.darkText
                                : AppTheme.lightText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isOpen ? '-' : '+',
                    style: TextStyle(
                      fontSize: 24,
                      color: isOpen
                          ? (isDark
                              ? AppTheme.brandTeal
                              : const Color(0xFF0D9488))
                          : isDark
                              ? AppTheme.darkTextMuted
                              : AppTheme.lightTextMuted,
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
                  color:
                      isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
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
        color: isDark ? AppTheme.darkSurface2 : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        'No results for "$_query". Try a different keyword.',
        style: TextStyle(
          color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
        ),
      ),
    );
  }

  Widget _footer(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: isDark ? const Color(0xFF070D12) : const Color(0xFF0F172A),
      child: Text(
        'Irrigation Water Requirements (IWR)\nISRO - IIRS - Department of Space, Govt. of India',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          height: 1.55,
          color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8),
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

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });
}

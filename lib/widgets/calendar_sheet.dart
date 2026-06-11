import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/history_model.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FloatingMiniCalendar - Option 2 style popup
// Width: 320px, Height: 350px max, never fullscreen
// ─────────────────────────────────────────────────────────────────────────────
class FloatingMiniCalendar extends StatefulWidget {
  final VoidCallback? onClose;

  const FloatingMiniCalendar({super.key, this.onClose});

  @override
  State<FloatingMiniCalendar> createState() => _FloatingMiniCalendarState();
}

class _FloatingMiniCalendarState extends State<FloatingMiniCalendar> {
  static const Set<int> _seasonMonths = {1, 2, 3, 4, 11, 12};
  static const List<String> _monthAbbr = ['Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr'];
  static const List<int> _monthNumbers = [11, 12, 1, 2, 3, 4];

  DateTime? _focusedMonth;
  int? _selectedYear;
  int? _selectedMonth;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    _focusedMonth = provider.selectedDate ?? DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth!.year, _focusedMonth!.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth!.year, _focusedMonth!.month + 1);
    });
  }

  void _selectYear(int year) {
    setState(() {
      _selectedYear = _selectedYear == year ? null : year;
      _focusedMonth = DateTime(year, _focusedMonth!.month);
    });
  }

  void _selectMonth(int month) {
    setState(() {
      _selectedMonth = _selectedMonth == month ? null : month;
      _focusedMonth = DateTime(_focusedMonth!.year, month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;

    final availableDates = provider.availableDates;
    final byDateMap = <String, AvailableDate>{};
    for (final item in availableDates) {
      byDateMap[item.date] = item;
    }

    final years = _getAvailableYears(availableDates);
    final monthsForYear = _selectedYear != null
        ? _getMonthsWithData(availableDates, _selectedYear!)
        : _monthNumbers.toSet().toList();

    final calendarDays = _buildCalendarDays(_focusedMonth!, byDateMap);

    final maxHeight = min(
      460.0,
      MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 24,
    );

    return Container(
      width: 320,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // ── header with month/year + close ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _previousMonth,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: _showYearPicker,
                        child: Text(
                          _focusedMonth != null
                              ? DateFormat('MMMM yyyy').format(_focusedMonth!)
                              : '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppTheme.lightText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _nextMonth,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _close(context),
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
              ],
            ),
          ),
          // ── day of week header ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                  .map((d) => Expanded(
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ))
                  .toList(),
            ),
          ),
          // ── calendar grid ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 1.2,
              children: calendarDays.map((day) => _MiniDayTile(
                day: day,
                isDark: isDark,
                selectedDate: provider.selectedDate,
                onTap: day.hasData
                    ? () {
                        provider.selectDate(day.date!);
                        _close(context);
                      }
                    : null,
              )).toList(),
            ),
          ),
          // ── filter pills (year + month) ──────────────────────────────────
          if (years.isNotEmpty || monthsForYear.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Year row
                  if (years.isNotEmpty)
                    _MiniFilterRow(
                      label: 'YEAR',
                      chips: [
                        _MiniFilterChip(
                          label: 'All',
                          active: _selectedYear == null,
                          isDark: isDark,
                          onTap: () => setState(() => _selectedYear = null),
                        ),
                        for (final y in years)
                          _MiniFilterChip(
                            label: y.toString(),
                            active: _selectedYear == y,
                            isDark: isDark,
                            onTap: () => _selectYear(y),
                          ),
                      ],
                      isDark: isDark,
                    ),
                  const SizedBox(height: 6),
                  // Month row (only when year selected)
                  if (_selectedYear != null)
                    _MiniFilterRow(
                      label: 'MONTH',
                      chips: [
                        _MiniFilterChip(
                          label: 'All',
                          active: _selectedMonth == null,
                          isDark: isDark,
                          onTap: () => setState(() => _selectedMonth = null),
                        ),
                        for (final m in monthsForYear)
                          _MiniFilterChip(
                            label: _monthNumberToAbbr(m),
                            active: _selectedMonth == m,
                            isDark: isDark,
                            onTap: () => _selectMonth(m),
                          ),
                      ],
                      isDark: isDark,
                    ),
                ],
              ),
            ),
          // ── bottom legend ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                _MiniLegendDot(color: AppTheme.brandTeal),
                const SizedBox(width: 4),
                Text(
                  'Historical Available',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const Spacer(),
                if (provider.selectedDate != null)
                  GestureDetector(
                    onTap: () {
                      provider.clearDate();
                      setState(() {});
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandTeal,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _showYearPicker() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final years = _getAvailableYears(provider.availableDates);
    if (years.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final isDark = provider.isDark;
        return Container(
          padding: const EdgeInsets.all(16),
          height: 280,
          color: isDark ? const Color(0xFF0E1E2C) : Colors.white,
          child: Column(
            children: [
              Text(
                'Select Year',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.lightText,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2,
                  ),
                  itemCount: years.length,
                  itemBuilder: (ctx, index) {
                    final year = years[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _focusedMonth = DateTime(year, _focusedMonth!.month));
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _focusedMonth?.year == year
                              ? AppTheme.brandPrimary.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _focusedMonth?.year == year
                                ? AppTheme.brandPrimary
                                : isDark
                                    ? Colors.white24
                                    : Colors.black12,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            year.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _focusedMonth?.year == year
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _focusedMonth?.year == year
                                  ? AppTheme.brandTeal
                                  : isDark
                                      ? Colors.white70
                                      : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<int> _getAvailableYears(List<AvailableDate> dates) {
    final years = <int>{};
    for (final date in dates) {
      final parts = date.date.split('-');
      if (parts.length >= 1) {
        years.add(int.parse(parts[0]));
      }
    }
    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  List<int> _getMonthsWithData(List<AvailableDate> dates, int year) {
    final months = <int>{};
    for (final date in dates) {
      final parts = date.date.split('-');
      if (parts.length >= 2 && int.parse(parts[0]) == year) {
        months.add(int.parse(parts[1]));
      }
    }
    return months.toList()..sort();
  }

  String _monthNumberToAbbr(int month) {
    const map = {
      1: 'Jan', 2: 'Feb', 3: 'Mar', 4: 'Apr', 5: 'May', 6: 'Jun',
      7: 'Jul', 8: 'Aug', 9: 'Sep', 10: 'Oct', 11: 'Nov', 12: 'Dec',
    };
    return map[month] ?? '';
  }

  List<_MiniCalendarDay> _buildCalendarDays(
    DateTime month,
    Map<String, AvailableDate> byDate,
  ) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;

    final List<_MiniCalendarDay> result = [];

    // Add empty cells for days before month starts
    for (int i = 0; i < firstWeekday; i++) {
      result.add(_MiniCalendarDay.empty());
    }

    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final iso = DateFormat('yyyy-MM-dd').format(date);
      final hasData = byDate.containsKey(iso);
      result.add(_MiniCalendarDay(day: day, date: date, hasData: hasData));
    }

    return result;
  }

  void _close(BuildContext context) {
    widget.onClose?.call();
    if (widget.onClose == null) {
      Navigator.maybePop(context);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini day tile
// ─────────────────────────────────────────────────────────────────────────────
class _MiniCalendarDay {
  final int? day;
  final DateTime? date;
  final bool hasData;

  _MiniCalendarDay({this.day, this.date, this.hasData = false});

  _MiniCalendarDay.empty()
      : day = null,
        date = null,
        hasData = false;
}

class _MiniDayTile extends StatelessWidget {
  final _MiniCalendarDay day;
  final bool isDark;
  final DateTime? selectedDate;
  final VoidCallback? onTap;

  const _MiniDayTile({
    required this.day,
    required this.isDark,
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (day.day == null) {
      return const SizedBox();
    }

    final isSelected = selectedDate != null &&
        day.date != null &&
        DateFormat('yyyy-MM-dd').format(selectedDate!) ==
            DateFormat('yyyy-MM-dd').format(day.date!);
    final isToday = day.date != null &&
        DateFormat('yyyy-MM-dd').format(DateTime.now()) ==
            DateFormat('yyyy-MM-dd').format(day.date!);

    return GestureDetector(
      onTap: day.hasData ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandPrimary
              : day.hasData
                  ? AppTheme.brandPrimary.withOpacity(isDark ? 0.20 : 0.10)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: Colors.orange.shade400, width: 1)
              : isSelected
                  ? Border.all(color: AppTheme.brandPrimary, width: 1)
                  : day.hasData
                      ? Border.all(
                          color: AppTheme.brandPrimary.withOpacity(0.30),
                          width: 0.5,
                        )
                      : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: day.hasData || isSelected
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: isSelected
                    ? Colors.white
                    : day.hasData
                        ? (isDark ? const Color(0xFFD4F5EA) : AppTheme.brandPrimary)
                        : isDark
                            ? Colors.white38
                            : Colors.black38,
              ),
            ),
            if (day.hasData && !isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: AppTheme.brandTeal,
                  shape: BoxShape.circle,
                ),
              )
            else if (day.hasData && isSelected)
              const SizedBox(height: 5)
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini filter row
// ─────────────────────────────────────────────────────────────────────────────
class _MiniFilterRow extends StatelessWidget {
  final String label;
  final List<Widget> chips;
  final bool isDark;

  const _MiniFilterRow({
    required this.label,
    required this.chips,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: isDark ? Colors.white30 : Colors.black38,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < chips.length; i++) ...[
                  chips[i],
                  if (i < chips.length - 1) const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniFilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  const _MiniFilterChip({
    required this.label,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.brandPrimary.withOpacity(0.22)
              : isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? AppTheme.brandPrimary.withOpacity(0.55)
                : isDark
                    ? Colors.white.withOpacity(0.10)
                    : Colors.black.withOpacity(0.08),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: active
                ? AppTheme.brandTeal
                : isDark
                    ? Colors.white60
                    : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _MiniLegendDot extends StatelessWidget {
  final Color color;

  const _MiniLegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
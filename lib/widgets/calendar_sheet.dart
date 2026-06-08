import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/history_model.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';

class CalendarSheet extends StatelessWidget {
  final VoidCallback? onClose;

  const CalendarSheet({super.key, this.onClose});

  static const Set<int> _seasonMonths = {1, 2, 3, 4, 11, 12};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;
    final months = _calendarMonths(provider.availableDates);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102235) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 8, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AppTheme.brandTeal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sentinel Dates',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppTheme.darkText
                                : AppTheme.lightText,
                          ),
                        ),
                        Text(
                          provider.availableDates.isEmpty
                              ? 'No imagery dates loaded'
                              : '${provider.availableDates.length} imagery dates available',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppTheme.darkTextMuted
                                : AppTheme.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (provider.selectedDate != null)
                    TextButton(
                      onPressed: provider.clearDate,
                      child: const Text('Clear'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => _close(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _body(context, provider, months, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppProvider provider,
    List<_CalendarMonth> months,
    bool isDark,
  ) {
    if (provider.historyLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (provider.historyError != null) {
      return _StateMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load imagery dates',
        message: provider.historyError!,
        actionLabel: 'Retry',
        onAction: provider.loadHistory,
        isDark: isDark,
      );
    }

    if (months.isEmpty) {
      return _StateMessage(
        icon: Icons.event_busy_outlined,
        title: 'No Sentinel imagery dates',
        message: 'The backend did not return processed history slots.',
        actionLabel: 'Refresh',
        onAction: provider.loadHistory,
        isDark: isDark,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: months.length,
      itemBuilder: (context, monthIndex) {
        final month = months[monthIndex];
        return _buildMonth(context, month, provider, isDark);
      },
    );
  }

  List<_CalendarMonth> _calendarMonths(List<AvailableDate> availableDates) {
    if (availableDates.isEmpty) return [];

    final byDate = <String, AvailableDate>{};
    for (final item in availableDates) {
      byDate[item.date] = item;
    }

    final sortedDates = byDate.keys.toList()..sort();
    final start = DateTime.parse('${sortedDates.first}T00:00:00');
    final end = DateTime.parse('${sortedDates.last}T00:00:00');
    final endMonth = DateTime(end.year, end.month);
    final months = <_CalendarMonth>[];

    var cursor = DateTime(start.year, start.month);
    while (!cursor.isAfter(endMonth)) {
      if (_seasonMonths.contains(cursor.month)) {
        months.add(_buildCalendarMonth(cursor, byDate));
      }
      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    return months.reversed.toList();
  }

  _CalendarMonth _buildCalendarMonth(
    DateTime month,
    Map<String, AvailableDate> byDate,
  ) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;
    final days = <_CalendarDay>[];

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final iso = DateFormat('yyyy-MM-dd').format(date);
      days.add(_CalendarDay(date: date, info: byDate[iso]));
    }

    final season = days
        .map((day) => day.info?.season ?? '')
        .firstWhere((season) => season.isNotEmpty, orElse: () => '');

    return _CalendarMonth(
      date: month,
      firstWeekday: firstWeekday,
      days: days,
      season: season,
    );
  }

  Widget _buildMonth(
    BuildContext context,
    _CalendarMonth month,
    AppProvider provider,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(month.date),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                ),
              ),
              if (month.season.isNotEmpty)
                _SeasonChip(season: month.season, isDark: isDark),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                .map(
                  (d) => SizedBox(
                    width: 36,
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            childAspectRatio: 0.86,
            children: [
              ...List.generate(month.firstWeekday, (_) => const SizedBox()),
              ...month.days.map(
                (day) => _CalendarDayTile(
                  day: day,
                  isDark: isDark,
                  selectedDate: provider.selectedDate,
                  onTap: day.info == null
                      ? null
                      : () {
                          provider.selectDate(day.date);
                          _close(context);
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _close(BuildContext context) {
    if (onClose != null) {
      onClose!();
    } else {
      Navigator.maybePop(context);
    }
  }
}

class _CalendarMonth {
  final DateTime date;
  final int firstWeekday;
  final List<_CalendarDay> days;
  final String season;

  const _CalendarMonth({
    required this.date,
    required this.firstWeekday,
    required this.days,
    required this.season,
  });
}

class _CalendarDay {
  final DateTime date;
  final AvailableDate? info;

  const _CalendarDay({
    required this.date,
    this.info,
  });
}

class _CalendarDayTile extends StatelessWidget {
  final _CalendarDay day;
  final bool isDark;
  final DateTime? selectedDate;
  final VoidCallback? onTap;

  const _CalendarDayTile({
    required this.day,
    required this.isDark,
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = day.info != null;
    final iso = DateFormat('yyyy-MM-dd').format(day.date);
    final selectedIso = selectedDate == null
        ? null
        : DateFormat('yyyy-MM-dd').format(selectedDate!);
    final isSelected = selectedIso == iso;
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == iso;
    final layerText = (day.info?.layers ?? const <String>[])
        .map((layer) => layer.toUpperCase())
        .take(2)
        .join(' ');

    return Tooltip(
      message: hasData
          ? '$iso - ${(day.info!.layers).join(', ').toUpperCase()}'
          : iso,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.brandPrimary
                : hasData
                    ? AppTheme.brandPrimary.withOpacity(isDark ? 0.22 : 0.14)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isToday
                  ? Colors.orange
                  : hasData
                      ? AppTheme.brandPrimary.withOpacity(0.34)
                      : Colors.transparent,
              width: isToday ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.date.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hasData || isSelected
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : hasData
                          ? (isDark
                              ? const Color(0xFFE5FFF8)
                              : AppTheme.brandPrimary)
                          : isDark
                              ? AppTheme.darkTextMuted
                              : AppTheme.lightTextMuted,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 10,
                child: hasData
                    ? Text(
                        layerText.isEmpty ? 'DATA' : layerText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 7.5,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : isDark
                                  ? AppTheme.brandTeal
                                  : AppTheme.brandPrimary,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeasonChip extends StatelessWidget {
  final String season;
  final bool isDark;

  const _SeasonChip({
    required this.season,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.brandAccent.withOpacity(isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.brandAccent.withOpacity(isDark ? 0.28 : 0.18),
        ),
      ),
      child: Text(
        season,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isDark ? AppTheme.darkTextSoft : AppTheme.brandAccent,
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isDark;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 34,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

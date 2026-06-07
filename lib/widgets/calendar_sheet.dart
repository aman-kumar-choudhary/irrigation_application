import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';

class CalendarSheet extends StatelessWidget {
  final VoidCallback? onClose;

  const CalendarSheet({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;

    // Generate 3 months for display
    final now = DateTime.now();
    final months = List.generate(3, (i) {
      final d = DateTime(now.year, now.month + i, 1);
      return d;
    });

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102235) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: AppTheme.brandTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Field Data Calendar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                      ),
                    ),
                  ),
                  if (provider.selectedDate != null)
                    TextButton(
                      onPressed: provider.clearDate,
                      child: const Text('Clear'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      if (onClose != null) {
                        onClose!();
                      } else {
                        Navigator.maybePop(context);
                      }
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: months.length,
                itemBuilder: (context, monthIndex) {
                  final month = months[monthIndex];
                  return _buildMonth(context, month, provider, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonth(
      BuildContext context, DateTime month, AppProvider provider, bool isDark) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(month),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          const SizedBox(height: 12),

          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                .map((d) => SizedBox(
                      width: 36,
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 8),

          // Days grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            childAspectRatio: 1,
            children: [
              // Empty cells
              ...List.generate(firstWeekday, (_) => const SizedBox()),

              // Days
              ...List.generate(daysInMonth, (day) {
                final date = DateTime(month.year, month.month, day + 1);
                final iso = DateFormat('yyyy-MM-dd').format(date);
                final hasData =
                    provider.availableDates.any((d) => d.date == iso);
                final isSelected = provider.selectedDate != null &&
                    DateFormat('yyyy-MM-dd').format(provider.selectedDate!) ==
                        iso;
                final isToday =
                    DateFormat('yyyy-MM-dd').format(DateTime.now()) == iso;

                return GestureDetector(
                  onTap: hasData
                      ? () {
                          provider.selectDate(date);
                          if (onClose != null) {
                            onClose!();
                          } else {
                            Navigator.maybePop(context);
                          }
                        }
                      : null,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.brandPrimary
                          : hasData
                              ? AppTheme.brandPrimary.withOpacity(0.2)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isToday
                          ? Border.all(color: Colors.orange, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected || hasData
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : hasData
                                    ? AppTheme.brandPrimary
                                    : isDark
                                        ? AppTheme.darkTextSoft
                                        : AppTheme.lightTextSoft,
                          ),
                        ),
                        if (hasData)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: const BoxDecoration(
                              color: AppTheme.brandPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

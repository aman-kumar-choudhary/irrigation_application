import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';

class CustomNavBar extends StatelessWidget {
  const CustomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;
    const items = [
      _NavItemData(Icons.home_outlined, Icons.home, 'Home'),
      _NavItemData(Icons.map_outlined, Icons.map, 'Map'),
      _NavItemData(Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat'),
      _NavItemData(Icons.article_outlined, Icons.article, 'Docs'),
      _NavItemData(Icons.help_outline, Icons.help, 'FAQs'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF071522) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.09),
            blurRadius: 18,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++)
              Expanded(
                child: _NavItem(
                  data: items[i],
                  active: provider.currentIndex == i,
                  isDark: isDark,
                  onTap: () => provider.setIndex(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData(this.icon, this.activeIcon, this.label);
}

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppTheme.brandTeal : AppTheme.brandPrimary;
    final inactiveColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withOpacity(isDark ? 0.16 : 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? activeColor.withOpacity(0.55) : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? data.activeIcon : data.icon,
              size: 20,
              color: active ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 2),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                height: 1,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/point_data_model.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LayerControlSheet
//
// Redesigned to match the target screenshot:
//  • Deep navy gradient background
//  • Workspace / "Map Controls" header with chevron close button
//  • Compact layer rows with icon badge + toggle + colour-coded legend bar
//  • Layer Opacity slider at bottom
// ─────────────────────────────────────────────────────────────────────────────
class LayerControlSheet extends StatefulWidget {
  final VoidCallback? onClose;

  const LayerControlSheet({super.key, this.onClose});

  @override
  State<LayerControlSheet> createState() => _LayerControlSheetState();
}

class _LayerControlSheetState extends State<LayerControlSheet> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF07121E), Color(0xFF0D1F30), Color(0xFF091828)],
                stops: [0.0, 0.55, 1.0],
              )
            : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.10)
              : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: false,
          radius: const Radius.circular(999),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── drag handle ──────────────────────────────────────────────
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.18)
                          : Colors.black.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // ── workspace header ─────────────────────────────────────────
                _WorkspaceHeader(
                  onClose: () {
                    if (widget.onClose != null) {
                      widget.onClose!();
                    } else {
                      Navigator.maybePop(context);
                    }
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 4),
                // ── section label ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                  child: _SectionLabel(label: 'RASTER LAYERS', isDark: isDark),
                ),
                // ── layer cards ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      for (final layer in Constants.layerDefinitions)
                        _LayerRow(
                          layer: layer,
                          active: provider.layers[layer['key']] ?? false,
                          isDark: isDark,
                          onTap: () =>
                              provider.toggleLayer(layer['key'] as String),
                          legendGradient:
                              _getLegendGradient(layer['key'] as String),
                        ),
                    ],
                  ),
                ),
                // ── opacity removed ──────────────────────────────────────────
              ],
            ),
          ),
        ),
      ),
    );
  }

  Gradient _getLegendGradient(String key) {
    switch (key) {
      case 'savi':
        return const LinearGradient(colors: [
          Color(0xFF8B0000),
          Color(0xFFFF4500),
          Color(0xFFFFD700),
          Color(0xFF32CD32),
          Color(0xFF006400),
        ]);
      case 'kc':
        return const LinearGradient(colors: [
          Color(0xFFFFD700),
          Color(0xFF90EE90),
          Color(0xFF32CD32),
          Color(0xFF8B4513),
        ]);
      case 'etc':
        return const LinearGradient(colors: [
          Color(0xFFFFFFFF),
          Color(0xFFB2EBF2),
          Color(0xFF26C6DA),
          Color(0xFF7CB342),
          Color(0xFFFFD54F),
          Color(0xFFEF6C00),
          Color(0xFF8E24AA),
        ]);
      case 'cwr':
        return const LinearGradient(colors: [
          Color(0xFFFF4444),
          Color(0xFFFFA500),
          Color(0xFFFFFF00),
          Color(0xFF0000CD),
          Color(0xFF4B0082),
        ]);
      case 'iwr':
        return const LinearGradient(colors: [
          Color(0xFFE0F7FA),
          Color(0xFF4DD0E1),
          Color(0xFF00BCD4),
          Color(0xFF00695C),
          Color(0xFF1A237E),
        ]);
      default:
        return const LinearGradient(colors: [Colors.grey, Colors.white]);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Workspace header  ── "WORKSPACE / Map Controls ‹ chevron ›"
// ─────────────────────────────────────────────────────────────────────────────
class _WorkspaceHeader extends StatelessWidget {
  final VoidCallback onClose;
  final bool isDark;

  const _WorkspaceHeader({required this.onClose, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 10, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WORKSPACE',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: isDark
                        ? const Color(0xFF5AC8A8)
                        : AppTheme.brandPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Map Controls',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.lightText,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          // chevron close button — matches screenshot
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.08),
                ),
              ),
              child: Icon(
                Icons.chevron_right,
                size: 22,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single layer row: icon badge | name + subtitle | toggle | legend bar
// ─────────────────────────────────────────────────────────────────────────────
class _LayerRow extends StatelessWidget {
  final Map<String, dynamic> layer;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;
  final Gradient legendGradient;

  const _LayerRow({
    required this.layer,
    required this.active,
    required this.isDark,
    required this.onTap,
    required this.legendGradient,
  });

  @override
  Widget build(BuildContext context) {
    final key = layer['key'] as String;
    final name = layer['name'] as String;
    final icon = (layer['icon'] as String? ?? '').trim();
    final minLabel = layer['minLabel'] as String? ?? '';
    final midLabel = layer['midLabel'] as String? ?? '';
    final maxLabel = layer['maxLabel'] as String? ?? '';

    return Column(
      children: [
        // ── main row ─────────────────────────────────────────────────────────
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: active
                  ? AppTheme.brandPrimary.withOpacity(isDark ? 0.18 : 0.10)
                  : isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? AppTheme.brandPrimary.withOpacity(0.42)
                    : isDark
                        ? Colors.white.withOpacity(0.09)
                        : Colors.black.withOpacity(0.07),
              ),
            ),
            child: Row(
              children: [
                // icon badge
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active
                        ? AppTheme.brandPrimary.withOpacity(0.26)
                        : isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active
                          ? AppTheme.brandPrimary.withOpacity(0.45)
                          : isDark
                              ? Colors.white.withOpacity(0.10)
                              : Colors.black.withOpacity(0.09),
                    ),
                  ),
                  child: Text(
                    icon.isEmpty
                        ? key.toUpperCase().substring(0, 2)
                        : icon,
                    style: TextStyle(
                      fontSize: icon.isEmpty ? 10 : 16,
                      fontWeight: FontWeight.w900,
                      color: active
                          ? Colors.white
                          : isDark
                              ? const Color(0xFFB0D0E8)
                              : AppTheme.lightText,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppTheme.lightText,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white.withOpacity(0.48)
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // custom toggle
                _ToggleTrack(active: active),
              ],
            ),
          ),
        ),
        // ── legend bar (only when active) ────────────────────────────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState:
              active ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.025),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Column(
              children: [
                // gradient bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(gradient: legendGradient),
                  ),
                ),
                const SizedBox(height: 6),
                // min / mid / max labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _LegendLabel(text: minLabel, isDark: isDark),
                    _LegendLabel(text: midLabel, isDark: isDark),
                    _LegendLabel(text: maxLabel, isDark: isDark),
                  ],
                ),
              ],
            ),
          ),
          secondChild: const SizedBox(height: 6),
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────
class _ToggleTrack extends StatelessWidget {
  final bool active;

  const _ToggleTrack({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 46,
      height: 24,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: active ? AppTheme.brandPrimary : const Color(0xFF2A3D50),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (active)
            BoxShadow(
              color: AppTheme.brandPrimary.withOpacity(0.36),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Align(
        alignment:
            active ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
        color: isDark
            ? Colors.white.withOpacity(0.38)
            : Colors.black.withOpacity(0.38),
      ),
    );
  }
}

class _LegendLabel extends StatelessWidget {
  final String text;
  final bool isDark;

  const _LegendLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontFamily: 'JetBrains Mono',
        color: isDark ? Colors.white54 : Colors.black45,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/point_data_model.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

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
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFA091623), Color(0xF5102837)],
              )
            : null,
        color: isDark ? null : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color:
                isDark ? Colors.white.withOpacity(0.12) : AppTheme.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          radius: const Radius.circular(999),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                  child: _workspaceHeader(context, isDark),
                ),
                _selectedPointPanel(provider, isDark),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _sectionLabel('Raster Layers', isDark),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                  child: Column(
                    children: [
                      for (final layer in Constants.layerDefinitions)
                        _layerCard(
                          layer: layer,
                          active: provider.layers[layer['key']] ?? false,
                          isDark: isDark,
                          onTap: () =>
                              provider.toggleLayer(layer['key'] as String),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  child: _baseMapControls(provider, isDark),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
                  child: _opacityControl(provider, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _workspaceHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.brandPrimary.withOpacity(isDark ? 0.18 : 0.10),
            AppTheme.brandAccent.withOpacity(isDark ? 0.12 : 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.12) : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workspace',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFF96D8B0)
                        : AppTheme.brandPrimary,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Map Controls',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              if (widget.onClose != null) {
                widget.onClose!();
              } else {
                Navigator.maybePop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _selectedPointPanel(AppProvider provider, bool isDark) {
    if (provider.selectedLocation == null &&
        provider.pointData == null &&
        !provider.pointLoading &&
        provider.pointError == null) {
      return const SizedBox.shrink();
    }

    final data = provider.pointData;
    final displayDate = data == null
        ? null
        : provider.selectedDate != null
            ? DateFormat('dd MMM yyyy').format(provider.selectedDate!)
            : data.acquisitionDate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              isDark ? Colors.white.withOpacity(0.045) : AppTheme.lightSurface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: isDark ? AppTheme.brandTeal : AppTheme.brandPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _sectionLabel('Selected Point', isDark),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (provider.pointLoading)
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Sampling pixel data',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextSoft
                          : AppTheme.lightTextSoft,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            else if (provider.pointError != null)
              Text(
                provider.pointError!,
                style: TextStyle(
                  color: Colors.orange.shade300,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              )
            else if (data != null) ...[
              _pointMetaRow(
                'Lat / Lon',
                '${data.lat.toStringAsFixed(5)}, ${data.lon.toStringAsFixed(5)}',
                isDark,
              ),
              if (displayDate != null)
                _pointMetaRow('Date', displayDate, isDark),
              if (data.pixelId != null)
                _pointMetaRow('Pixel', data.pixelId!, isDark),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final layer in Constants.layerDefinitions)
                    _pointValueChip(layer, data, isDark),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pointMetaRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
                fontWeight: FontWeight.w800,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pointValueChip(
    Map<String, dynamic> layer,
    PointData data,
    bool isDark,
  ) {
    final key = layer['key'] as String;
    final value = data.values[key];
    final unit = layer['unit'] as String? ?? '';
    final displayValue =
        value == null ? 'No data' : '${value.toStringAsFixed(3)} $unit'.trim();

    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF081420) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            key.toUpperCase(),
            style: TextStyle(
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            displayValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _layerCard({
    required Map<String, dynamic> layer,
    required bool active,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final key = layer['key'] as String;
    final icon = (layer['icon'] as String? ?? '').trim();

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      colors: [
                        AppTheme.brandPrimary.withOpacity(isDark ? 0.22 : 0.13),
                        AppTheme.brandAccent.withOpacity(isDark ? 0.12 : 0.08),
                      ],
                    )
                  : null,
              color: active
                  ? null
                  : isDark
                      ? Colors.white.withOpacity(0.045)
                      : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active
                    ? AppTheme.brandPrimary.withOpacity(0.55)
                    : isDark
                        ? Colors.white.withOpacity(0.12)
                        : AppTheme.lightBorder,
              ),
              boxShadow: [
                if (active)
                  BoxShadow(
                    color: AppTheme.brandPrimary.withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active
                        ? AppTheme.brandPrimary.withOpacity(0.28)
                        : AppTheme.brandAccent
                            .withOpacity(isDark ? 0.13 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active
                          ? AppTheme.brandPrimary.withOpacity(0.36)
                          : AppTheme.brandAccent.withOpacity(0.18),
                    ),
                  ),
                  child: Text(
                    icon.isEmpty ? key.toUpperCase().substring(0, 2) : icon,
                    style: TextStyle(
                      fontSize: icon.isEmpty ? 11 : 16,
                      fontWeight: FontWeight.w900,
                      color:
                          isDark ? const Color(0xFFEAF6FC) : AppTheme.lightText,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? AppTheme.darkText : AppTheme.lightText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        layer['name'] as String? ?? 'Unknown',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.25,
                          color: isDark
                              ? AppTheme.darkTextMuted
                              : AppTheme.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _toggleTrack(active),
              ],
            ),
          ),
        ),
        if (active)
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF081420).withOpacity(0.48)
                  : AppTheme.lightSurface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : AppTheme.lightBorder,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _legendLabel(layer['minLabel'] as String, isDark),
                    _legendLabel(layer['midLabel'] as String, isDark),
                    _legendLabel(layer['maxLabel'] as String, isDark),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: _getLegendGradient(key),
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox(height: 10),
      ],
    );
  }

  Widget _baseMapControls(AppProvider provider, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Base Map', isDark),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _choiceChip(
              label: 'Street',
              icon: Icons.map_outlined,
              active: provider.mapStyle == 'street',
              onTap: () => provider.setMapStyle('street'),
              isDark: isDark,
            ),
            _choiceChip(
              label: 'Focus',
              icon: Icons.dark_mode_outlined,
              active: provider.mapStyle == 'focus',
              onTap: () => provider.setMapStyle('focus'),
              isDark: isDark,
            ),
            _choiceChip(
              label: 'Satellite',
              icon: Icons.satellite_alt_outlined,
              active: provider.mapStyle == 'satellite',
              onTap: () => provider.setMapStyle('satellite'),
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _opacityControl(AppProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppTheme.lightSurface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Layer Opacity',
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                ),
              ),
              Text(
                '${(provider.opacity * 100).round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color:
                      isDark ? const Color(0xFFCFE9DA) : AppTheme.brandPrimary,
                ),
              ),
            ],
          ),
          Slider(
            value: provider.opacity,
            onChanged: provider.setOpacity,
            min: 0,
            max: 1,
            divisions: 20,
            activeColor: AppTheme.brandPrimary,
            inactiveColor:
                isDark ? const Color(0xFF415A71) : Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _toggleTrack(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 44,
      height: 22,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: active ? AppTheme.brandPrimary : const Color(0xFF415A71),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (active)
            BoxShadow(
              color: AppTheme.brandPrimary.withOpacity(0.18),
              blurRadius: 12,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Align(
        alignment: active ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontFamily: 'JetBrains Mono',
        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
      ),
    );
  }

  Widget _sectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _choiceChip({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.brandPrimary.withOpacity(isDark ? 0.28 : 0.14)
              : isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppTheme.brandPrimary
                : isDark
                    ? AppTheme.darkBorder
                    : AppTheme.lightBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active
                  ? AppTheme.brandTeal
                  : isDark
                      ? AppTheme.darkTextMuted
                      : AppTheme.lightTextMuted,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active
                    ? (isDark ? Colors.white : AppTheme.brandPrimary)
                    : isDark
                        ? AppTheme.darkTextSoft
                        : AppTheme.lightTextSoft,
              ),
            ),
          ],
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
          Color(0xFF006400)
        ]);
      case 'kc':
        return const LinearGradient(colors: [
          Color(0xFFFFD700),
          Color(0xFF90EE90),
          Color(0xFF32CD32),
          Color(0xFF8B4513)
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
          Color(0xFF4B0082)
        ]);
      case 'iwr':
        return const LinearGradient(colors: [
          Color(0xFFE0F7FA),
          Color(0xFF4DD0E1),
          Color(0xFF00BCD4),
          Color(0xFF00695C),
          Color(0xFF1A237E)
        ]);
      default:
        return const LinearGradient(colors: [Colors.grey, Colors.white]);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

class MapView extends StatefulWidget {
  final MapController mapController;
  final double bottomInset;
  final void Function(Offset screenPosition)? onTapScreenPosition;

  const MapView({
    super.key,
    required this.mapController,
    this.bottomInset = 0,
    this.onTapScreenPosition,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  static const LatLng _defaultCenter = LatLng(29.0, 79.4);
  static const double _defaultZoom = 9.0;
  static const double _minZoom = 8.0;
  static const double _maxZoom = 17.0;
  static const double _boundaryPaddingFraction = 0.12;

  List<Polygon> _boundaryPolygons = [];
  bool _boundaryLoading = true;
  LatLng _visibleCenter = _defaultCenter;
  double _visibleZoom = _defaultZoom;
  LatLngBounds? _boundaryBounds;
  LatLngBounds? _paddedBoundaryBounds;

  @override
  void initState() {
    super.initState();
    _loadBoundary();
  }

  Future<void> _loadBoundary() async {
    try {
      final data = await ApiService().fetchBoundary();
      final geojson = data['geojson'] is Map<String, dynamic>
          ? data['geojson'] as Map<String, dynamic>
          : <String, dynamic>{};
      var polygons = _extractPolygons(geojson);

      if (polygons.isEmpty) {
        final boundsRing = _boundsToRing(data['bounds']);
        if (boundsRing.isNotEmpty) {
          polygons = [_buildBoundaryPolygon(boundsRing)];
        }
      }

      if (polygons.isNotEmpty && mounted) {
        final allPoints = polygons.expand((p) => p.points).toList();
        if (allPoints.isNotEmpty) {
          _boundaryBounds = LatLngBounds.fromPoints(allPoints);
          _paddedBoundaryBounds = _padBounds(
            _boundaryBounds!,
            _boundaryPaddingFraction,
          );

          setState(() {
            _boundaryPolygons = polygons;
          });

          // Fit camera after layout is complete
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _boundaryBounds == null) return;
            try {
              widget.mapController.fitCamera(
                CameraFit.bounds(
                  bounds: _boundaryBounds!,
                  padding: const EdgeInsets.all(24),
                  maxZoom: _maxZoom - 1,
                ),
              );
            } catch (e) {
              debugPrint('Boundary camera fit error: $e');
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Boundary load error: $e');
    } finally {
      if (mounted) {
        setState(() => _boundaryLoading = false);
      }
    }
  }

  List<Polygon> _extractPolygons(Map<String, dynamic> geojson) {
    final rings = <List<LatLng>>[];

    void readGeometry(Map<String, dynamic> geom) {
      final type = geom['type']?.toString();
      final coords = geom['coordinates'];
      if (type == 'Polygon' && coords is List && coords.isNotEmpty) {
        final ring = _ringToPoints(coords.first);
        if (ring.length >= 3) rings.add(ring);
      } else if (type == 'MultiPolygon' && coords is List) {
        for (final polygon in coords) {
          if (polygon is List && polygon.isNotEmpty) {
            final ring = _ringToPoints(polygon.first);
            if (ring.length >= 3) rings.add(ring);
          }
        }
      }
    }

    try {
      final type = geojson['type']?.toString();
      if (type == 'FeatureCollection') {
        final features = geojson['features'];
        if (features is List) {
          for (final feature in features) {
            if (feature is Map<String, dynamic> &&
                feature['geometry'] is Map<String, dynamic>) {
              readGeometry(feature['geometry'] as Map<String, dynamic>);
            }
          }
        }
      } else if (type == 'Feature' &&
          geojson['geometry'] is Map<String, dynamic>) {
        readGeometry(geojson['geometry'] as Map<String, dynamic>);
      } else {
        readGeometry(geojson);
      }
    } catch (e) {
      debugPrint('GeoJSON parse error: $e');
    }
    return rings.map(_buildBoundaryPolygon).toList();
  }

  List<LatLng> _ringToPoints(dynamic rawRing) {
    if (rawRing is! List) return [];
    return rawRing
        .whereType<List>()
        .map((c) {
          if (c.length < 2) return null;
          final lon = _asDouble(c[0]);
          final lat = _asDouble(c[1]);
          if (lat == null || lon == null) return null;
          return LatLng(lat, lon);
        })
        .whereType<LatLng>()
        .toList();
  }

  List<LatLng> _boundsToRing(dynamic rawBounds) {
    if (rawBounds is! Map) return [];
    final n = _asDouble(rawBounds['north']);
    final s = _asDouble(rawBounds['south']);
    final e = _asDouble(rawBounds['east']);
    final w = _asDouble(rawBounds['west']);
    if (n == null || s == null || e == null || w == null) return [];
    return [
      LatLng(s, w),
      LatLng(s, e),
      LatLng(n, e),
      LatLng(n, w),
      LatLng(s, w),
    ];
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Polygon _buildBoundaryPolygon(List<LatLng> points) {
    return Polygon(
      points: points,
      color: const Color(0xFF19C7A6).withOpacity(0.07),
      borderColor: const Color(0xFF19C7A6),
      borderStrokeWidth: 2.2,
      isDotted: true,
    );
  }

  LatLngBounds _padBounds(LatLngBounds bounds, double ratio) {
    final latPad = (bounds.north - bounds.south).abs() * ratio;
    final lonPad = (bounds.east - bounds.west).abs() * ratio;
    return LatLngBounds(
      LatLng(bounds.south - latPad, bounds.west - lonPad),
      LatLng(bounds.north + latPad, bounds.east + lonPad),
    );
  }

  List<Widget> _buildWMSLayers(AppProvider provider) {
    final layers = <Widget>[];
    final slot = provider.currentSlot;

    provider.layers.forEach((key, active) {
      if (!active) return;
      final layerName = provider.forecastWindow != null && key == 'kc'
          ? 'kc_${slot}_${provider.forecastWindow}'
          : '${key}_$slot';

      layers.add(
        TileLayer(
          wmsOptions: WMSTileLayerOptions(
            baseUrl: '${ApiConfig.geoserverUrl}/${ApiConfig.workspace}/wms?',
            layers: ['${ApiConfig.workspace}:$layerName'],
            styles: ['${key}_style'],
            format: 'image/png',
            version: '1.3.0',
            transparent: true,
            crs: const Epsg3857(),
            uppercaseBoolValue: true,
            otherParameters: const {'tiled': 'true'},
          ),
          userAgentPackageName: 'com.example.aquawatch',
          tileBuilder: provider.opacity < 1
              ? (context, tileWidget, tile) =>
                  Opacity(opacity: provider.opacity, child: tileWidget)
              : null,
        ),
      );
    });
    return layers;
  }

  _BaseMapStyle _baseStyle(String key) {
    switch (key) {
      case 'focus':
        return const _BaseMapStyle(
          name: 'Focus',
          key: 'focus',
          url: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: ['a', 'b', 'c'],
          retina: true,
          thumbnail: 'https://b.basemaps.cartocdn.com/dark_all/4/8/8.png',
        );
      case 'satellite':
        return const _BaseMapStyle(
          name: 'Satellite',
          key: 'satellite',
          url:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          subdomains: [],
          thumbnail:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/4/8/8',
        );
      case 'street':
      default:
        return const _BaseMapStyle(
          name: 'Street',
          key: 'street',
          url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: [],
          thumbnail: 'https://tile.openstreetmap.org/4/8/8.png',
        );
    }
  }

  List<_BaseMapStyle> get _baseMapChoices => const [
        _BaseMapStyle(
          name: 'Satellite',
          key: 'satellite',
          url:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          subdomains: [],
          thumbnail:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/4/8/8',
        ),
        _BaseMapStyle(
          name: 'Street',
          key: 'street',
          url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: [],
          thumbnail: 'https://tile.openstreetmap.org/4/8/8.png',
        ),
        _BaseMapStyle(
          name: 'Focus',
          key: 'focus',
          url: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: ['a', 'b', 'c'],
          retina: true,
          thumbnail: 'https://b.basemaps.cartocdn.com/dark_all/4/8/8.png',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final baseStyle = _baseStyle(provider.mapStyle);
    final selectedPoint = provider.pointData == null
        ? provider.selectedLocation
        : LatLng(provider.pointData!.lat, provider.pointData!.lon);

    return Stack(
      children: [
        // Map Layer - takes full space
        FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: _defaultZoom,
            minZoom: _minZoom,
            maxZoom: _maxZoom,
            cameraConstraint: _paddedBoundaryBounds == null
                ? const CameraConstraint.unconstrained()
                : CameraConstraint.containCenter(
                    bounds: _paddedBoundaryBounds!,
                  ),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            onPositionChanged: (position, hasGesture) {
              final c = position.center;
              final z = position.zoom;
              if (c == null && z == null) return;
              setState(() {
                if (c != null) _visibleCenter = c;
                if (z != null) _visibleZoom = z;
              });
            },
            onTap: (tapPosition, latLng) {
              provider.fetchPointData(latLng);
              if (widget.onTapScreenPosition != null) {
                widget.onTapScreenPosition!(tapPosition.global);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: baseStyle.url,
              subdomains: baseStyle.subdomains,
              retinaMode: baseStyle.retina
                  ? RetinaMode.isHighDensity(context)
                  : false,
              userAgentPackageName: 'com.example.aquawatch',
            ),
            if (provider.mapStyle == 'satellite')
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c'],
                retinaMode: RetinaMode.isHighDensity(context),
                userAgentPackageName: 'com.example.aquawatch',
              ),
            ..._buildWMSLayers(provider),
            if (_boundaryPolygons.isNotEmpty)
              PolygonLayer(polygons: _boundaryPolygons),
            if (selectedPoint != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: selectedPoint,
                    width: 48,
                    height: 48,
                    child: const _LocationMarker(),
                  ),
                ],
              ),
          ],
        ),

        // Floating UI Elements - positioned to avoid overlap
        // Top Status Pill - below safe area
        if (_boundaryLoading || provider.pointLoading)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Center(
              child: _StatusPill(
                loading: true,
                message: _boundaryLoading
                    ? 'Loading boundary...'
                    : 'Loading pixel data...',
              ),
            ),
          ),

        // Bottom Controls Container - positioned above bottom inset
        Positioned(
          left: 0,
          right: 0,
          bottom: widget.bottomInset + 12,
          child: Center(
            child: _BasemapSwitcher(
              choices: _baseMapChoices,
              selectedKey: provider.mapStyle,
              onSelected: provider.setMapStyle,
            ),
          ),
        ),

        // Zoom Controls - Right side
        Positioned(
          right: 12,
          bottom: widget.bottomInset + 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ZoomButton(
                icon: Icons.add,
                onPressed: () {
                  final newZoom =
                      (_visibleZoom + 1).clamp(_minZoom, _maxZoom).toDouble();
                  widget.mapController.move(_visibleCenter, newZoom);
                },
              ),
              const SizedBox(height: 8),
              _ZoomButton(
                icon: Icons.remove,
                onPressed: () {
                  final newZoom =
                      (_visibleZoom - 1).clamp(_minZoom, _maxZoom).toDouble();
                  widget.mapController.move(_visibleCenter, newZoom);
                },
              ),
              const SizedBox(height: 8),
              _ZoomButton(
                icon: Icons.crop_free,
                onPressed: _boundaryBounds != null
                    ? () {
                        widget.mapController.fitCamera(
                          CameraFit.bounds(
                            bounds: _boundaryBounds!,
                            padding: const EdgeInsets.all(24),
                            maxZoom: _maxZoom - 1,
                          ),
                        );
                      }
                    : null,
                isActive: true,
              ),
              const SizedBox(height: 8),
              _ZoomButton(
                icon: Icons.my_location,
                onPressed: () {
                  widget.mapController.move(_defaultCenter, _defaultZoom);
                },
              ),
            ],
          ),
        ),

        // Coordinate Display - Top left
        Positioned(
          left: 12,
          top: MediaQuery.of(context).padding.top +
              (_boundaryLoading || provider.pointLoading ? 56 : 12),
          child: _CoordinateReadout(
            center: _visibleCenter,
          ),
        ),
      ],
    );
  }
}

// Custom zoom button widget
class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isActive;

  const _ZoomButton({
    required this.icon,
    this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: onPressed != null
                  ? (isActive ? AppTheme.brandTeal : const Color(0xFF1A2B3C))
                  : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationMarker extends StatelessWidget {
  const _LocationMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.brandTeal.withOpacity(0.16),
            border: Border.all(
              color: AppTheme.brandTeal.withOpacity(0.38),
              width: 1.5,
            ),
          ),
        ),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.brandTeal.withOpacity(0.28),
            border: Border.all(
              color: AppTheme.brandTeal.withOpacity(0.70),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.location_on,
            color: AppTheme.brandTeal,
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _CoordinateReadout extends StatelessWidget {
  final LatLng center;

  const _CoordinateReadout({required this.center});

  @override
  Widget build(BuildContext context) {
    final point = center;
    const label = 'Center';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xCC07131F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.explore_outlined, size: 12, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            '$label  ${point.latitude.toStringAsFixed(5)}, '
            '${point.longitude.toStringAsFixed(5)}',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool loading;
  final String message;

  const _StatusPill({required this.loading, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xEC081420),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.brandTeal,
              ),
            ),
          if (loading) const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BasemapSwitcher extends StatelessWidget {
  final List<_BaseMapStyle> choices;
  final String selectedKey;
  final ValueChanged<String> onSelected;

  const _BasemapSwitcher({
    required this.choices,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xA8050A11),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < choices.length; i++) ...[
            _BasemapCard(
              style: choices[i],
              active: selectedKey == choices[i].key,
              onTap: () => onSelected(choices[i].key),
            ),
            if (i < choices.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _BasemapCard extends StatelessWidget {
  final _BaseMapStyle style;
  final bool active;
  final VoidCallback onTap;

  const _BasemapCard({
    required this.style,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xCC030C16)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? const Color(0xEA5CCDFF)
                : Colors.white.withOpacity(0.10),
          ),
        ),
        child: Text(
          style.name,
          style: TextStyle(
            color: active ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _BaseMapStyle {
  final String name;
  final String key;
  final String url;
  final List<String> subdomains;
  final bool retina;
  final String thumbnail;

  const _BaseMapStyle({
    required this.name,
    this.key = '',
    required this.url,
    required this.subdomains,
    this.retina = false,
    this.thumbnail = '',
  });
}

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

  const MapView({super.key, required this.mapController});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  List<Polygon> boundaryPolygons = [];
  bool boundaryLoading = true;

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

      if (polygons.isNotEmpty) {
        final allPoints = polygons.expand((p) => p.points).toList();
        if (!mounted) return;
        setState(() => boundaryPolygons = polygons);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || allPoints.isEmpty) return;
          try {
            widget.mapController.fitCamera(
              CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(allPoints),
                padding: const EdgeInsets.all(28),
                maxZoom: 12,
              ),
            );
          } catch (e) {
            debugPrint('Boundary fit error: $e');
          }
        });
      }
    } catch (e) {
      debugPrint('Boundary error: $e');
    } finally {
      if (mounted) {
        setState(() => boundaryLoading = false);
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
      debugPrint('Parse error: $e');
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
    final north = _asDouble(rawBounds['north']);
    final south = _asDouble(rawBounds['south']);
    final east = _asDouble(rawBounds['east']);
    final west = _asDouble(rawBounds['west']);
    if (north == null || south == null || east == null || west == null) {
      return [];
    }
    return [
      LatLng(south, west),
      LatLng(south, east),
      LatLng(north, east),
      LatLng(north, west),
      LatLng(south, west),
    ];
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Polygon _buildBoundaryPolygon(List<LatLng> points) {
    return Polygon(
      points: points,
      color: Colors.transparent,
      borderColor: const Color(0xFF19C7A6),
      borderStrokeWidth: 2.5,
      isDotted: true,
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
              ? (context, tileWidget, tile) {
                  return Opacity(
                    opacity: provider.opacity,
                    child: tileWidget,
                  );
                }
              : null,
        ),
      );
    });

    return layers;
  }

  _BaseMapStyle _baseStyle(String selectedStyle) {
    switch (selectedStyle) {
      case 'focus':
        return const _BaseMapStyle(
          name: 'Focus',
          url: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: ['a', 'b', 'c'],
          retina: true,
          thumbnail: 'https://b.basemaps.cartocdn.com/dark_all/4/8/8.png',
        );
      case 'satellite':
        return const _BaseMapStyle(
          name: 'Satellite',
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
          url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: [],
          thumbnail: 'https://tile.openstreetmap.org/4/8/8.png',
        );
    }
  }

  List<_BaseMapStyle> get _baseMapChoices => const [
        _BaseMapStyle(
          name: 'Street',
          key: 'street',
          url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: [],
          thumbnail: 'https://tile.openstreetmap.org/4/8/8.png',
        ),
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

    return Stack(
      children: [
        FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: const LatLng(29.0, 79.4),
            initialZoom: 9.0,
            minZoom: 5,
            maxZoom: 18,
            onTap: (tapPosition, latLng) {
              provider.fetchPointData(latLng);
            },
          ),
          children: [
            // Base layer
            TileLayer(
              urlTemplate: baseStyle.url,
              subdomains: baseStyle.subdomains,
              retinaMode:
                  baseStyle.retina ? RetinaMode.isHighDensity(context) : false,
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

            // WMS Layers
            ..._buildWMSLayers(provider),

            // Boundary
            if (boundaryPolygons.isNotEmpty)
              PolygonLayer(polygons: boundaryPolygons),

            // Selected location marker
            if (provider.selectedLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: provider.selectedLocation!,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.brandTeal.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.brandTeal.withOpacity(0.52),
                        ),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppTheme.brandTeal,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 10,
          child: _BasemapSwitcher(
            choices: _baseMapChoices,
            selectedKey: provider.mapStyle,
            onSelected: provider.setMapStyle,
          ),
        ),
      ],
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
    final maxSwitcherWidth = (MediaQuery.sizeOf(context).width - 20).clamp(
      0.0,
      double.infinity,
    );

    return IgnorePointer(
      ignoring: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxSwitcherWidth,
          ),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xA3050A11),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x57000000),
                blurRadius: 42,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final choice in choices) ...[
                  _BasemapCard(
                    style: choice,
                    active: selectedKey == choice.key,
                    onTap: () => onSelected(choice.key),
                  ),
                  if (choice != choices.last) const SizedBox(width: 7),
                ],
              ],
            ),
          ),
        ),
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
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: active ? 1.06 : 1,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: active ? 1 : 0.72,
          child: Container(
            width: 78,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xC2030C16)
                  : Colors.white.withOpacity(0.045),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active
                    ? const Color(0xEA5CCDFF)
                    : Colors.white.withOpacity(0.12),
              ),
              boxShadow: [
                if (active)
                  const BoxShadow(
                    color: Color(0x803B9FD9),
                    blurRadius: 22,
                  ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      style.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: style.key == 'focus'
                                ? const [
                                    Color(0xFF050810),
                                    Color(0xFF1A3550),
                                  ]
                                : style.key == 'satellite'
                                    ? const [
                                        Color(0xFF325A3C),
                                        Color(0xFF7A8A64),
                                      ]
                                    : const [
                                        Color(0xFFDBEAFE),
                                        Color(0xFF8DB5D8),
                                      ],
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.62),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          style.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

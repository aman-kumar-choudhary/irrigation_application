class PointData {
  final double lat;
  final double lon;
  final String acquisitionDate;
  final String slot;
  final String? pixelId;
  final int? row;
  final int? col;
  final double? queryLat;
  final double? queryLon;
  final Map<String, double?> values;
  final Map<String, dynamic>? forecast;

  PointData({
    required this.lat,
    required this.lon,
    required this.acquisitionDate,
    required this.slot,
    this.pixelId,
    this.row,
    this.col,
    this.queryLat,
    this.queryLon,
    required this.values,
    this.forecast,
  });

  factory PointData.fromJson(Map<String, dynamic> json) {
    final values = <String, double?>{};
    (json['values'] as Map<String, dynamic>?)?.forEach((k, v) {
      values[k] = _asDouble(v);
    });

    return PointData(
      lat: _asDouble(json['lat']) ?? 0,
      lon: _asDouble(json['lon']) ?? 0,
      acquisitionDate: json['acquisition_date']?.toString() ?? 'N/A',
      slot: json['slot']?.toString() ?? 'today',
      pixelId: json['pixel_id']?.toString(),
      row: _asInt(json['row']),
      col: _asInt(json['col']),
      queryLat: _asDouble(json['query_lat']),
      queryLon: _asDouble(json['query_lon']),
      values: values,
      forecast: json['forecast'] is Map<String, dynamic>
          ? json['forecast'] as Map<String, dynamic>
          : null,
    );
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

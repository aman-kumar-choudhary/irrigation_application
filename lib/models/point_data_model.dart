class PointData {
  final double lat;
  final double lon;
  final String acquisitionDate;
  final Map<String, double?> values;
  final Map<String, dynamic>? forecast;

  PointData({
    required this.lat,
    required this.lon,
    required this.acquisitionDate,
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
}

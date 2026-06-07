class ChartData {
  final String layer;
  final List<int> years;
  final List<String> months;
  final List<String> monthNames;
  final List<YearData> data;
  final Map<String, dynamic>? layerConfig;

  ChartData({
    required this.layer,
    required this.years,
    required this.months,
    required this.monthNames,
    required this.data,
    this.layerConfig,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      layer: json['layer']?.toString() ?? '',
      years: (json['years'] as List<dynamic>? ?? [])
          .map(_asInt)
          .whereType<int>()
          .toList(),
      months: (json['months'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      monthNames: (json['month_names'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      data: (json['data'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => YearData.fromJson(e))
              .toList() ??
          [],
      layerConfig: json['layer_config'] is Map<String, dynamic>
          ? json['layer_config'] as Map<String, dynamic>
          : null,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class YearData {
  final int year;
  final List<double?> monthly;
  final List<double?> cumulative;

  YearData({
    required this.year,
    required this.monthly,
    required this.cumulative,
  });

  factory YearData.fromJson(Map<String, dynamic> json) {
    return YearData(
      year: ChartData._asInt(json['year']) ?? 0,
      monthly: (json['monthly'] as List<dynamic>?)
              ?.map(_asNullableDouble)
              .toList() ??
          [],
      cumulative: (json['cumulative'] as List<dynamic>?)
              ?.map(_asNullableDouble)
              .toList() ??
          [],
    );
  }

  static double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

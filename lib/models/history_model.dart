class AvailableDate {
  final String date;
  final String slot;
  final List<String> layers;
  final String season;
  final int? month;
  final int? year;

  AvailableDate({
    required this.date,
    required this.slot,
    required this.layers,
    this.season = '',
    this.month,
    this.year,
  });

  factory AvailableDate.fromJson(Map<String, dynamic> json) {
    final obsMeans = json['obs_means'] as Map<String, dynamic>?;
    final layers = json['layers'] is List
        ? List<String>.from(json['layers'] as List)
        : obsMeans?.entries
                .where((entry) => entry.value != null)
                .map((entry) => entry.key)
                .toList() ??
            <String>[];

    return AvailableDate(
      date: json['date'],
      slot: json['slot'] ?? 'today',
      layers: layers,
      season: json['season']?.toString() ?? '',
      month: json['month'] is num ? (json['month'] as num).toInt() : null,
      year: json['year'] is num ? (json['year'] as num).toInt() : null,
    );
  }
}

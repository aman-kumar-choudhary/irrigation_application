class AvailableDate {
  final String date;
  final String slot;
  final List<String> layers;

  AvailableDate({
    required this.date,
    required this.slot,
    required this.layers,
  });

  factory AvailableDate.fromJson(Map<String, dynamic> json) {
    return AvailableDate(
      date: json['date'],
      slot: json['slot'] ?? 'today',
      layers: List<String>.from(json['layers'] ?? []),
    );
  }
}
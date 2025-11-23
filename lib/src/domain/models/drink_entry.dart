class DrinkEntry {
  final String id;
  final String drinkTypeId;
  final int sizeMl;
  final DateTime timestamp;

  const DrinkEntry({
    required this.id,
    required this.drinkTypeId,
    required this.sizeMl,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'drinkTypeId': drinkTypeId,
      'sizeMl': sizeMl,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static DrinkEntry fromJson(Map<String, dynamic> json) {
    return DrinkEntry(
      id: json['id'] as String,
      drinkTypeId: json['drinkTypeId'] as String,
      sizeMl: (json['sizeMl'] as num).toInt(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

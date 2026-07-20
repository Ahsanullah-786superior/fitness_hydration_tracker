class WaterEntry {
  final String id;
  final int amountMl;
  final DateTime timestamp;

  WaterEntry({
    required this.id,
    required this.amountMl,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amountMl': amountMl,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WaterEntry.fromMap(Map<String, dynamic> map) {
    return WaterEntry(
      id: map['id'] as String,
      amountMl: map['amountMl'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

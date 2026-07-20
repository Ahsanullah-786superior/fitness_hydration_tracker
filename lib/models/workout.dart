class Workout {
  final String id;
  final String type; // e.g. Running, Cycling, Gym, Yoga
  final int durationMinutes;
  final int caloriesBurned;
  final int steps;
  final DateTime date;
  final String? notes;

  Workout({
    required this.id,
    required this.type,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.steps,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'steps': steps,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] as String,
      type: map['type'] as String,
      durationMinutes: map['durationMinutes'] as int,
      caloriesBurned: map['caloriesBurned'] as int,
      steps: map['steps'] as int,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
    );
  }
}

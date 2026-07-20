import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../db/database_helper.dart';
import '../models/workout.dart';

class FitnessProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  List<Workout> _workouts = [];
  List<Workout> get workouts => _workouts;

  List<Workout> _todaysWorkouts = [];
  List<Workout> get todaysWorkouts => _todaysWorkouts;

  int get todaysSteps =>
      _todaysWorkouts.fold(0, (sum, w) => sum + w.steps);

  int get todaysCalories =>
      _todaysWorkouts.fold(0, (sum, w) => sum + w.caloriesBurned);

  int get todaysMinutes =>
      _todaysWorkouts.fold(0, (sum, w) => sum + w.durationMinutes);

  Future<void> loadAll() async {
    _workouts = await _db.getWorkouts();
    _todaysWorkouts = await _db.getWorkoutsForDate(DateTime.now());
    notifyListeners();
  }

  Future<void> addWorkout({
    required String type,
    required int durationMinutes,
    required int caloriesBurned,
    required int steps,
    String? notes,
  }) async {
    final workout = Workout(
      id: _uuid.v4(),
      type: type,
      durationMinutes: durationMinutes,
      caloriesBurned: caloriesBurned,
      steps: steps,
      date: DateTime.now(),
      notes: notes,
    );
    await _db.insertWorkout(workout);
    await loadAll();
  }

  Future<void> deleteWorkout(String id) async {
    await _db.deleteWorkout(id);
    await loadAll();
  }

  /// Returns total calories burned per day for the last [days] days,
  /// keyed by day label (e.g. "Mon").
  Map<String, int> caloriesByDay(int days) {
    final now = DateTime.now();
    final Map<String, int> result = {};
    for (int i = days - 1; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final label = _weekdayLabel(day.weekday);
      final total = _workouts
          .where((w) =>
              w.date.year == day.year &&
              w.date.month == day.month &&
              w.date.day == day.day)
          .fold(0, (sum, w) => sum + w.caloriesBurned);
      result[label] = total;
    }
    return result;
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }
}

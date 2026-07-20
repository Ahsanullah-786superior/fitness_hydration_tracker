import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../db/database_helper.dart';
import '../models/water_entry.dart';
import '../services/notification_service.dart';

class WaterProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  static const int defaultGoalMl = 2500;
  static const int defaultReminderIntervalMinutes = 90;

  int _dailyGoalMl = defaultGoalMl;
  int get dailyGoalMl => _dailyGoalMl;

  int _reminderIntervalMinutes = defaultReminderIntervalMinutes;
  int get reminderIntervalMinutes => _reminderIntervalMinutes;

  bool _remindersEnabled = true;
  bool get remindersEnabled => _remindersEnabled;

  List<WaterEntry> _todaysEntries = [];
  List<WaterEntry> get todaysEntries => _todaysEntries;

  int get todaysTotalMl =>
      _todaysEntries.fold(0, (sum, e) => sum + e.amountMl);

  double get progress =>
      (_dailyGoalMl == 0) ? 0 : (todaysTotalMl / _dailyGoalMl).clamp(0, 1.5);

  Future<void> init() async {
    final goalStr = await _db.getSetting('daily_goal_ml');
    if (goalStr != null) _dailyGoalMl = int.tryParse(goalStr) ?? defaultGoalMl;

    final intervalStr = await _db.getSetting('reminder_interval_minutes');
    if (intervalStr != null) {
      _reminderIntervalMinutes =
          int.tryParse(intervalStr) ?? defaultReminderIntervalMinutes;
    }

    final remindersStr = await _db.getSetting('reminders_enabled');
    if (remindersStr != null) _remindersEnabled = remindersStr == 'true';

    await loadToday();

    if (_remindersEnabled) {
      await NotificationService.instance.scheduleHydrationReminders(
        intervalMinutes: _reminderIntervalMinutes,
      );
    }
  }

  Future<void> loadToday() async {
    _todaysEntries = await _db.getWaterEntriesForDate(DateTime.now());
    notifyListeners();
  }

  Future<void> addWater(int amountMl) async {
    final entry = WaterEntry(
      id: _uuid.v4(),
      amountMl: amountMl,
      timestamp: DateTime.now(),
    );
    await _db.insertWaterEntry(entry);
    await loadToday();
  }

  Future<void> removeEntry(String id) async {
    await _db.deleteWaterEntry(id);
    await loadToday();
  }

  Future<void> resetToday() async {
    await _db.clearWaterEntriesForDate(DateTime.now());
    await loadToday();
  }

  Future<void> setDailyGoal(int goalMl) async {
    _dailyGoalMl = goalMl;
    await _db.setSetting('daily_goal_ml', goalMl.toString());
    notifyListeners();
  }

  Future<void> setReminderInterval(int minutes) async {
    _reminderIntervalMinutes = minutes;
    await _db.setSetting('reminder_interval_minutes', minutes.toString());
    if (_remindersEnabled) {
      await NotificationService.instance.scheduleHydrationReminders(
        intervalMinutes: minutes,
      );
    }
    notifyListeners();
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    _remindersEnabled = enabled;
    await _db.setSetting('reminders_enabled', enabled.toString());
    if (enabled) {
      await NotificationService.instance.scheduleHydrationReminders(
        intervalMinutes: _reminderIntervalMinutes,
      );
    } else {
      await NotificationService.instance.cancelAllReminders();
    }
    notifyListeners();
  }

  /// Weekly totals in ml, oldest first, for the stats chart.
  Future<Map<String, int>> weeklyTotals() async {
    final entries = await _db.getWaterEntriesLastNDays(7);
    final now = DateTime.now();
    final Map<String, int> result = {};
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final label = _weekdayLabel(day.weekday);
      final total = entries
          .where((e) =>
              e.timestamp.year == day.year &&
              e.timestamp.month == day.month &&
              e.timestamp.day == day.day)
          .fold(0, (sum, e) => sum + e.amountMl);
      result[label] = total;
    }
    return result;
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'hydration_channel';
  static const String _channelName = 'Hydration Reminders';
  static const String _channelDesc =
      'Reminders to drink water and stay hydrated';

  Future<void> init() async {
    if (kIsWeb) return;

    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);

    // Android 13+ needs explicit runtime permission for notifications.
    await Permission.notification.request();

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Schedules a repeating reminder every [intervalMinutes] starting from now,
  /// only firing between [startHour] and [endHour] (24h format) to avoid
  /// waking the user overnight.
  Future<void> scheduleHydrationReminders({
    required int intervalMinutes,
    int startHour = 8,
    int endHour = 22,
  }) async {
    if (kIsWeb) return;
    await cancelAllReminders();

    final now = tz.TZDateTime.now(tz.local);
    var next = now.add(Duration(minutes: intervalMinutes));

    // Generate a batch of reminders across the active window for today/tomorrow.
    int id = 1000;
    while (next.hour >= startHour && next.hour < endHour ||
        next.isBefore(now.add(const Duration(days: 1)))) {
      if (next.hour >= startHour && next.hour < endHour) {
        await _plugin.zonedSchedule(
          id,
          'Time to hydrate 💧',
          'You haven\'t logged water in a while. Take a sip!',
          next,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDesc,
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        id++;
      }
      next = next.add(Duration(minutes: intervalMinutes));
      if (id > 1050) break; // safety cap
    }
  }

  Future<void> showInstantReminder() async {
    if (kIsWeb) return;
    await _plugin.show(
      9999,
      'Stay hydrated 💧',
      'Log your next glass of water to keep your streak going.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelAllReminders() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}

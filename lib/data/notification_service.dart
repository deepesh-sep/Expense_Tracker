import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _initialize() async {
    if (_initialized) {
      return;
    }
    timezone_data.initializeTimeZones();
    if (!kIsWeb &&
        defaultTargetPlatform != TargetPlatform.linux &&
        defaultTargetPlatform != TargetPlatform.windows) {
      final zone = await FlutterTimezone.getLocalTimezone();
      timezone.setLocalLocation(timezone.getLocation(zone.identifier));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _initialized = true;
  }

  Future<bool> _requestPermission() async {
    await _initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return true;
  }

  Future<bool> requestNotificationPermission() => _requestPermission();

  Future<bool> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return false;
    }
    if (!await _requestPermission()) {
      return false;
    }
    final now = timezone.TZDateTime.now(timezone.local);
    var scheduled = timezone.TZDateTime(
      timezone.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id: 1,
      title: 'Log today’s expenses',
      body: 'Take a moment to keep your expense tracker up to date.',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'expense_reminders',
          'Expense reminders',
          channelDescription: 'Daily reminders to log expenses',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    return true;
  }

  Future<void> cancelDailyReminder() async {
    await _initialize();
    await _plugin.cancel(id: 1);
  }

  Future<bool> showBudgetAlert({
    required int id,
    required String title,
    required String message,
  }) async {
    if (kIsWeb || !await _requestPermission()) {
      return false;
    }
    await _plugin.show(
      id: id,
      title: title,
      body: message,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_alerts',
          'Budget alerts',
          channelDescription: 'Alerts when nearing or exceeding your budget',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    return true;
  }
}

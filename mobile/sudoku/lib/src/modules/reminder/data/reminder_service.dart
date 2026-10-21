import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku/src/modules/reminder/domain/model/reminder_settings.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract class ReminderService {
  Future<ReminderSettings> load();

  /// Schedules the daily reminder. Returns false, leaving the reminder off,
  /// when notification permission is denied.
  Future<bool> enable(int hour, int minute);

  Future<void> disable();
}

/// Daily reminder as a repeating local notification. The plugin and time
/// zones are set up on first use so they don't slow down app startup.
class LocalReminderService implements ReminderService {
  static const _notificationId = 1;
  static const _enabledKey = 'reminder.enabled';
  static const _hourKey = 'reminder.hour';
  static const _minuteKey = 'reminder.minute';

  final FlutterLocalNotificationsPlugin plugin;
  final SharedPreferencesAsync prefs;
  Future<void>? _ready;

  LocalReminderService({
    FlutterLocalNotificationsPlugin? plugin,
    SharedPreferencesAsync? prefs,
  }) : plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       prefs = prefs ?? SharedPreferencesAsync();

  Future<void> _ensureReady() => _ready ??= () async {
    tz_data.initializeTimeZones();
    final local = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(local.identifier));
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested when the reminder is turned on.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }();

  @override
  Future<ReminderSettings> load() async {
    return ReminderSettings(
      enabled: await prefs.getBool(_enabledKey) ?? false,
      hour: await prefs.getInt(_hourKey) ?? ReminderSettings.defaultHour,
      minute: await prefs.getInt(_minuteKey) ?? ReminderSettings.defaultMinute,
    );
  }

  @override
  Future<bool> enable(int hour, int minute) async {
    await _ensureReady();
    if (!await _requestPermission()) return false;

    await plugin.zonedSchedule(
      id: _notificationId,
      title: 'Time for Sudoku',
      body: "Today's puzzle is waiting for you.",
      scheduledDate: _nextInstanceOf(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily reminder',
          channelDescription: 'A daily reminder to play a puzzle',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Inexact avoids the exact-alarm permission; a few minutes' drift is
      // fine for a reminder.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await prefs.setBool(_enabledKey, true);
    await prefs.setInt(_hourKey, hour);
    await prefs.setInt(_minuteKey, minute);
    return true;
  }

  @override
  Future<void> disable() async {
    await _ensureReady();
    await plugin.cancel(id: _notificationId);
    await prefs.setBool(_enabledKey, false);
  }

  Future<bool> _requestPermission() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Null below Android 13, where no runtime permission is needed.
        return await plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission() ??
            true;
      case TargetPlatform.iOS:
        return await plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, sound: true) ??
            false;
      default:
        return false;
    }
  }

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return next;
  }
}

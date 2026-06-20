import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/models.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.1);

    _initialized = true;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Speak task name and vibrate when notification is tapped
    if (response.id != null && response.id! < 99998) {
      final taskName = response.payload;
      if (taskName != null && taskName.isNotEmpty) {
        speakTaskName(taskName);
      }
      triggerAlarmVibration();
    }
  }

  static Future<void> scheduleTaskAlarm(RoutineTask task, int weekday) async {
    if (!task.alarmEnabled) return;

    final parts = task.time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final vibPat = Int64List.fromList([0, 500, 300, 500, 300, 500]);

    final androidDetails = AndroidNotificationDetails(
      'fasn_alarms',
      'Task Alarms',
      channelDescription: 'Alarms for your daily tasks',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibPat,
      category: AndroidNotificationCategory.alarm,
    );

    final details = NotificationDetails(android: androidDetails);
    final id = _generateNotificationId(task.id, weekday);

    await _notifications.zonedSchedule(
      id,
      'Time for: ${task.name}',
      'Tap to check off your task',
      scheduledDate,
      details,
      payload: task.name,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static Future<void> cancelTaskAlarm(String taskId, int weekday) async {
    await _notifications.cancel(_generateNotificationId(taskId, weekday));
  }

  static Future<void> cancelAllAlarms() async {
    await _notifications.cancelAll();
  }

  static int _generateNotificationId(String taskId, int weekday) {
    return (taskId + weekday.toString()).hashCode.abs() % 100000;
  }

  static Future<void> speakTaskName(String taskName) async {
    await _tts.speak(taskName);
  }

  static Future<void> triggerAlarmVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 800, 400, 800, 400, 800, 400, 800]);
    }
  }

  static Future<void> scheduleMotivationalNotification({
    required bool isMorning,
    required String quote,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final hour = isMorning ? 8 : 21;
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, 0);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

    const androidDetails = AndroidNotificationDetails(
      'fasn_motivation',
      'Daily Motivation',
      channelDescription: 'Your daily motivational message',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _notifications.zonedSchedule(
      isMorning ? 99998 : 99999,
      isMorning ? 'Good morning, beautiful!' : 'End your day with love',
      quote,
      scheduled,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

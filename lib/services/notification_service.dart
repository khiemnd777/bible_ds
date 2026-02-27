import 'dart:convert';

import 'package:bible_decision_simulator/models/notification_rule.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

typedef CompletedTodayResolver = Future<bool> Function();

class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const String _configPath = 'assets/config/notification_config.json';
  static const AndroidNotificationChannel _defaultChannel =
      AndroidNotificationChannel(
    'daily_turning_reminders',
    'Daily Turning Reminders',
    description: 'Scheduled reminders for daily scenes and streaks.',
    importance: Importance.high,
  );

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    await _configureLocalTimeZone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: android,
        iOS: ios,
      ),
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_defaultChannel);

    _initialized = true;
  }

  Future<NotificationConfig> loadConfig() async {
    final raw = await rootBundle.loadString(_configPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return NotificationConfig.fromJson(data);
  }

  Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited || status.isProvisional;
  }

  Future<bool> requestPermission() async {
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted =
        await androidPlugin?.requestNotificationsPermission();

    return (iosGranted ?? true) && (androidGranted ?? true);
  }

  Future<void> openSystemNotificationSettings() async {
    await openAppSettings();
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> scheduleAll({
    required CompletedTodayResolver hasCompletedToday,
    required String localeCode,
  }) async {
    await init();

    final config = await loadConfig();
    await cancelAll();

    final completed = await hasCompletedToday();
    for (final rule in config.notifications) {
      if (!rule.enabled) continue;
      if (rule.onlyIfNotCompletedToday && completed) continue;
      await scheduleRule(rule, localeCode: localeCode);
    }
  }

  Future<void> scheduleRule(
    NotificationRule rule, {
    required String localeCode,
  }) {
    switch (rule.type) {
      case NotificationRuleType.dailyTime:
        return _scheduleDaily(rule, localeCode: localeCode);
      case NotificationRuleType.weeklyTime:
        return _scheduleWeekly(rule, localeCode: localeCode);
      case NotificationRuleType.oneTime:
        return _scheduleOneTime(rule, localeCode: localeCode);
    }
  }

  Future<void> _scheduleDaily(
    NotificationRule rule, {
    required String localeCode,
  }) async {
    await _plugin.zonedSchedule(
      _notificationIntId(rule.id),
      rule.title.resolve(localeCode),
      rule.body.resolve(localeCode),
      _nextDaily(rule.hour, rule.minute),
      _buildDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: rule.id,
    );
  }

  Future<void> _scheduleWeekly(
    NotificationRule rule, {
    required String localeCode,
  }) async {
    await _plugin.zonedSchedule(
      _notificationIntId(rule.id),
      rule.title.resolve(localeCode),
      rule.body.resolve(localeCode),
      _nextWeekly(
        weekday: rule.weekday!,
        hour: rule.hour,
        minute: rule.minute,
      ),
      _buildDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: rule.id,
    );
  }

  Future<void> _scheduleOneTime(
    NotificationRule rule, {
    required String localeCode,
  }) async {
    await _plugin.zonedSchedule(
      _notificationIntId(rule.id),
      rule.title.resolve(localeCode),
      rule.body.resolve(localeCode),
      _nextOneTime(rule.hour, rule.minute),
      _buildDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: rule.id,
    );
  }

  NotificationDetails _buildDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _defaultChannel.id,
        _defaultChannel.name,
        channelDescription: _defaultChannel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  tz.TZDateTime _nextDaily(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextWeekly({
    required int weekday,
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextOneTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  int _notificationIntId(String input) {
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = 0x1fffffff & (hash + input.codeUnitAt(i));
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash;
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }
}

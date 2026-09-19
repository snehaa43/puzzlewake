import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/alarm.dart';

/// Top-level background notification response handler
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Entry point for background notification actions if needed
  debugPrint('Background notification tapped with payload: ${notificationResponse.payload}');
}

/// Service managing system notifications, exact background alarms,
/// upcoming 5-minute reminder alerts, and notification click navigation.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    _ensureTimezonesInitialized();
  }

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _pendingAlarmLaunchId;

  /// Callback when user taps an alarm notification
  void Function(String alarmId)? onAlarmNotificationTriggered;

  void _ensureTimezonesInitialized() {
    try {
      tz.initializeTimeZones();
      try {
        // Test accessing tz.local
        final _ = tz.local;
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (e) {
      debugPrint('Timezone initialization note: $e');
    }
  }

  /// Initialize local notifications and device timezone
  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Initialize Timezones
    _ensureTimezonesInitialized();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Could not fetch local timezone, fallback: $e');
    }

    // 2. Android Initialization Settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS / Darwin Initialization Settings
    const DarwinInitializationSettings darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    // 4. Initialize Plugin
    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            _handlePayload(payload);
          }
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      // 5. Check if app was launched via notification click
      final launchDetails = await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final payload = launchDetails?.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          _pendingAlarmLaunchId = _extractAlarmId(payload);
        }
      }
    } catch (e) {
      debugPrint('Notification plugin initialize note: $e');
    }

    _isInitialized = true;
  }

  /// Request runtime permissions on Android 13+ and exact alarm permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final bool? notifGranted = await androidImplementation?.requestNotificationsPermission();
      final bool? exactGranted = await androidImplementation?.requestExactAlarmsPermission();
      return (notifGranted ?? true) && (exactGranted ?? true);
    } else if (Platform.isIOS) {
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final bool? granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// Consume pending alarm ID if the app was launched by tapping a notification
  String? consumePendingAlarmLaunchId() {
    final id = _pendingAlarmLaunchId;
    _pendingAlarmLaunchId = null;
    return id;
  }

  void _handlePayload(String payload) {
    final alarmId = _extractAlarmId(payload);
    if (alarmId.isNotEmpty) {
      if (onAlarmNotificationTriggered != null) {
        onAlarmNotificationTriggered!(alarmId);
      } else {
        _pendingAlarmLaunchId = alarmId;
      }
    }
  }

  String _extractAlarmId(String payload) {
    if (payload.startsWith('preview_')) {
      return payload.replaceFirst('preview_', '');
    }
    return payload;
  }

  int _getAlarmNotificationId(String alarmId) {
    return (alarmId.hashCode.abs() % 100000);
  }

  int _getPreAlarmNotificationId(String alarmId) {
    return (alarmId.hashCode.abs() % 100000) + 100000;
  }

  int _getUpcomingNoticeNotificationId(String alarmId) {
    return (alarmId.hashCode.abs() % 100000) + 200000;
  }

  /// Main full-screen ringing alarm notification details
  NotificationDetails _alarmNotificationDetails(Alarm alarm) {
    final androidDetails = AndroidNotificationDetails(
      'puzzlewake_alarm_channel_v2',
      'PuzzleWake Alarms',
      channelDescription: 'Ringing alarms requiring jigsaw puzzle completion to dismiss',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      playSound: true,
      ongoing: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        'Time to wake up! Solve the puzzle to dismiss this alarm.',
        contentTitle: '⏰ Alarm: ${alarm.label} (${alarm.formattedTime()})',
        summaryText: 'Puzzle Alarm Active',
      ),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    return NotificationDetails(android: androidDetails, iOS: darwinDetails);
  }

  /// 5-minute pre-alarm upcoming reminder notification details
  NotificationDetails _reminderNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'puzzlewake_reminder_channel_v2',
      'Upcoming Alarm Reminders',
      channelDescription: 'Advance reminder notifications (e.g. Alarm in 5 minutes)',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      enableVibration: true,
      playSound: true,
      autoCancel: true,
      visibility: NotificationVisibility.public,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return const NotificationDetails(android: androidDetails, iOS: darwinDetails);
  }

  /// Schedules both the exact ringing alarm and the 5-minute advance reminder
  Future<void> scheduleAlarmNotification(Alarm alarm) async {
    if (!alarm.enabled) {
      await cancelAlarmNotification(alarm.id);
      return;
    }

    try {
      final now = DateTime.now();
      final triggerDateTime = alarm.getNextTriggerDateTime(now);
      final scheduledTZ = tz.TZDateTime.from(triggerDateTime, tz.local);

      // 1. Schedule exact ringing alarm
      await _notificationsPlugin.zonedSchedule(
        id: _getAlarmNotificationId(alarm.id),
        title: '⏰ ${alarm.label}',
        body: 'Tap to solve the puzzle and turn off the alarm!',
        scheduledDate: scheduledTZ,
        notificationDetails: _alarmNotificationDetails(alarm),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: alarm.id,
      );

      // 2. Schedule 5-minute pre-alarm reminder if trigger is more than 5 minutes away
      final preAlarmDateTime = triggerDateTime.subtract(const Duration(minutes: 5));
      if (preAlarmDateTime.isAfter(now)) {
        final preScheduledTZ = tz.TZDateTime.from(preAlarmDateTime, tz.local);
        await _notificationsPlugin.zonedSchedule(
          id: _getPreAlarmNotificationId(alarm.id),
          title: '⏰ Alarm in 5 minutes',
          body: '${alarm.label} is scheduled for ${alarm.formattedTime()}',
          scheduledDate: preScheduledTZ,
          notificationDetails: _reminderNotificationDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'preview_${alarm.id}',
        );
      } else {
        // If alarm is set for <= 5 minutes from now, cancel any stale pre-alarm
        await _notificationsPlugin.cancel(id: _getPreAlarmNotificationId(alarm.id));
      }

      debugPrint('Scheduled background alarm for ${alarm.label} at $scheduledTZ');
    } catch (e) {
      debugPrint('Error scheduling alarm notification: $e');
    }
  }

  /// Display an immediate confirmation notification when alarm is set or in 5 minutes
  Future<void> showUpcomingAlarmAlert(Alarm alarm, String timeRemainingText) async {
    try {
      await _notificationsPlugin.show(
        id: _getUpcomingNoticeNotificationId(alarm.id),
        title: '⏰ Alarm Set: ${alarm.label}',
        body: '$timeRemainingText (${alarm.formattedTime()})',
        notificationDetails: _reminderNotificationDetails(),
        payload: 'preview_${alarm.id}',
      );
    } catch (e) {
      debugPrint('Error showing upcoming alarm alert: $e');
    }
  }

  /// Cancels all notifications (alarm, pre-alarm, notice) for a given alarm
  Future<void> cancelAlarmNotification(String alarmId) async {
    try {
      await _notificationsPlugin.cancel(id: _getAlarmNotificationId(alarmId));
      await _notificationsPlugin.cancel(id: _getPreAlarmNotificationId(alarmId));
      await _notificationsPlugin.cancel(id: _getUpcomingNoticeNotificationId(alarmId));
      debugPrint('Cancelled notifications for alarm $alarmId');
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
  }

  /// Resynchronizes all saved alarms with the system notification scheduler
  Future<void> rescheduleAllAlarms(List<Alarm> alarms) async {
    for (final alarm in alarms) {
      if (alarm.enabled) {
        await scheduleAlarmNotification(alarm);
      } else {
        await cancelAlarmNotification(alarm.id);
      }
    }
  }

  /// Dismiss active ringing notification when puzzle is solved
  Future<void> dismissRingingNotification(String alarmId) async {
    try {
      await _notificationsPlugin.cancel(id: _getAlarmNotificationId(alarmId));
    } catch (e) {
      debugPrint('Error dismissing ringing notification: $e');
    }
  }
}

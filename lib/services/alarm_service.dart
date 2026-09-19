import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alarm.dart';
import 'storage_service.dart';
import 'sound_service.dart';
import 'notification_service.dart';

/// Central service responsible for managing alarms, background scheduling, triggering ringing, and puzzle resolution.
class AlarmService extends ChangeNotifier {
  final StorageService storage;
  final SoundService soundService;
  final NotificationService notificationService;

  List<Alarm> _alarms = [];
  Alarm? _activeRingingAlarm;
  Timer? _tickerTimer;
  DateTime? _lastCheckedMinute;

  // Global callback for UI navigation when alarm triggers
  void Function(Alarm alarm)? onAlarmTriggered;

  AlarmService({
    required this.storage,
    required this.soundService,
    required this.notificationService,
  }) {
    _init();
  }

  List<Alarm> get alarms => List.unmodifiable(_alarms);
  Alarm? get activeRingingAlarm => _activeRingingAlarm;
  bool get isAlarmRinging => _activeRingingAlarm != null;

  void _init() {
    _alarms = storage.loadAlarms();

    // Listen for notification interactions (tapped alarm notification)
    notificationService.onAlarmNotificationTriggered = (alarmId) {
      triggerAlarmById(alarmId);
    };

    // Reschedule all active alarms with system notification manager (reboots/cold boot)
    notificationService.rescheduleAllAlarms(_alarms);

    // Check if app was launched via notification click
    final pendingLaunchId = notificationService.consumePendingAlarmLaunchId();
    if (pendingLaunchId != null) {
      final matched = _alarms.where((a) => a.id == pendingLaunchId).toList();
      if (matched.isNotEmpty) {
        _triggerAlarm(matched.first, isResume: true);
      }
    } else {
      // Check if an alarm was ringing before app restart/cold boot
      final activeId = storage.getActiveAlarmId();
      if (activeId != null) {
        final matched = _alarms.where((a) => a.id == activeId).toList();
        if (matched.isNotEmpty) {
          _triggerAlarm(matched.first, isResume: true);
        }
      }
    }

    // Start precision time monitor (1-second tick) for foreground precision
    _startSchedulerTicker();
  }

  /// High precision scheduler loop checking every second against enabled alarms
  void _startSchedulerTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkAlarms();
    });
  }

  void _checkAlarms() {
    if (_activeRingingAlarm != null) return; // Already ringing

    final now = DateTime.now();
    // Only evaluate once per clock minute
    if (_lastCheckedMinute != null &&
        _lastCheckedMinute!.year == now.year &&
        _lastCheckedMinute!.month == now.month &&
        _lastCheckedMinute!.day == now.day &&
        _lastCheckedMinute!.hour == now.hour &&
        _lastCheckedMinute!.minute == now.minute) {
      return;
    }

    for (final alarm in _alarms) {
      if (!alarm.enabled) continue;

      final isMatchingTime = alarm.time.hour == now.hour && alarm.time.minute == now.minute;

      if (isMatchingTime) {
        if (alarm.repeatDays.isEmpty) {
          // Once alarm: triggers today at this time
          _lastCheckedMinute = now;
          _triggerAlarm(alarm);
          break;
        } else if (alarm.repeatDays.contains(now.weekday)) {
          // Repeating alarm matching today's weekday
          _lastCheckedMinute = now;
          _triggerAlarm(alarm);
          break;
        }
      }
    }
  }

  /// Trigger alarm by its unique string ID
  void triggerAlarmById(String id) {
    final matched = _alarms.where((a) => a.id == id).toList();
    if (matched.isNotEmpty) {
      _triggerAlarm(matched.first);
    }
  }

  /// Triggers the alarm: plays audio in loop, enables vibration, stores active state, and opens AlarmScreen
  void _triggerAlarm(Alarm alarm, {bool isResume = false}) async {
    _activeRingingAlarm = alarm;
    await storage.setActiveAlarmId(alarm.id);

    final volume = storage.getAlarmVolume();
    final vibration = storage.getVibrationEnabled();

    // Determine sound to play: specific alarm sound or fallback to default
    String soundName = alarm.sound;
    if (soundName.isEmpty) {
      soundName = storage.getDefaultSound();
    }

    await soundService.playAlarmSound(
      soundName,
      volume: volume,
      enableVibration: vibration,
    );

    notifyListeners();

    // Trigger navigation callback to display the full screen alarm & puzzle
    if (onAlarmTriggered != null) {
      onAlarmTriggered!(alarm);
    }
  }

  /// Called when user successfully solves the jigsaw puzzle!
  Future<void> onPuzzleCompleted() async {
    if (_activeRingingAlarm == null) return;

    final completedAlarm = _activeRingingAlarm!;

    // 1. Immediately stop alarm audio and vibration
    await soundService.stopAlarmSound();

    // 2. Clear active ringing state & dismiss ringing notification
    await storage.setActiveAlarmId(null);
    await notificationService.dismissRingingNotification(completedAlarm.id);
    _activeRingingAlarm = null;

    // 3. If it was a one-time alarm, disable it; if repeating, reschedule next occurrence
    final index = _alarms.indexWhere((a) => a.id == completedAlarm.id);
    if (index != -1) {
      if (completedAlarm.repeatDays.isEmpty) {
        _alarms[index] = completedAlarm.copyWith(enabled: false);
        await storage.saveAlarms(_alarms);
        await notificationService.cancelAlarmNotification(completedAlarm.id);
      } else {
        // Reschedule next repeating trigger
        await notificationService.scheduleAlarmNotification(completedAlarm);
      }
    }

    notifyListeners();
  }

  /// Add a new alarm and schedule it with system notifications
  Future<void> addAlarm(Alarm alarm) async {
    _alarms.add(alarm);
    await storage.saveAlarms(_alarms);
    if (alarm.enabled) {
      await notificationService.scheduleAlarmNotification(alarm);
      // If alarm is set for upcoming time, provide feedback
      final remaining = getNextAlarmTimeRemaining();
      if (remaining != null) {
        await notificationService.showUpcomingAlarmAlert(alarm, remaining);
      }
    }
    notifyListeners();
  }

  /// Update an existing alarm and synchronize system notifications
  Future<void> updateAlarm(Alarm updated) async {
    final index = _alarms.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      _alarms[index] = updated;
      await storage.saveAlarms(_alarms);
      if (updated.enabled) {
        await notificationService.scheduleAlarmNotification(updated);
        final remaining = getNextAlarmTimeRemaining();
        if (remaining != null) {
          await notificationService.showUpcomingAlarmAlert(updated, remaining);
        }
      } else {
        await notificationService.cancelAlarmNotification(updated.id);
      }
      notifyListeners();
    }
  }

  /// Delete an alarm and cancel its notifications
  Future<void> deleteAlarm(String id) async {
    _alarms.removeWhere((a) => a.id == id);
    await storage.saveAlarms(_alarms);
    await notificationService.cancelAlarmNotification(id);
    notifyListeners();
  }

  /// Toggle alarm ON / OFF and update system notifications
  Future<void> toggleAlarm(String id, bool isEnabled) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      final updated = _alarms[index].copyWith(enabled: isEnabled);
      _alarms[index] = updated;
      await storage.saveAlarms(_alarms);
      if (isEnabled) {
        await notificationService.scheduleAlarmNotification(updated);
        final remaining = getNextAlarmTimeRemaining();
        if (remaining != null) {
          await notificationService.showUpcomingAlarmAlert(updated, remaining);
        }
      } else {
        await notificationService.cancelAlarmNotification(id);
      }
      notifyListeners();
    }
  }

  /// Get the earliest upcoming alarm trigger information for home screen summary
  String? getNextAlarmTimeRemaining() {
    final enabledAlarms = _alarms.where((a) => a.enabled).toList();
    if (enabledAlarms.isEmpty) return null;

    final now = DateTime.now();
    DateTime? earliest;

    for (final alarm in enabledAlarms) {
      final next = alarm.getNextTriggerDateTime(now);
      if (earliest == null || next.isBefore(earliest)) {
        earliest = next;
      }
    }

    if (earliest == null) return null;

    final diff = earliest.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    if (hours == 0 && minutes == 0) {
      return 'Alarm in less than a minute';
    } else if (hours == 0) {
      return 'Alarm in $minutes min';
    } else if (minutes == 0) {
      return 'Alarm in $hours hr';
    } else {
      return 'Alarm in $hours hr $minutes min';
    }
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }
}


import 'package:flutter/material.dart';

/// Represents an alarm configured in PuzzleWake.
class Alarm {
  final String id;
  final TimeOfDay time;
  final bool enabled;
  final List<int> repeatDays; // 1 = Monday ... 7 = Sunday. Empty = Once
  final String sound;
  final String label;

  Alarm({
    required this.id,
    required this.time,
    this.enabled = true,
    this.repeatDays = const [],
    this.sound = 'Classic Alarm',
    this.label = 'Wake Up',
  });

  /// Check if the alarm repeats
  bool get isRepeating => repeatDays.isNotEmpty;

  /// Check if repeating every day (1..7)
  bool get isEveryDay => repeatDays.length == 7;

  /// Check if weekdays only (1..5)
  bool get isWeekdays =>
      repeatDays.length == 5 &&
      repeatDays.contains(1) &&
      repeatDays.contains(2) &&
      repeatDays.contains(3) &&
      repeatDays.contains(4) &&
      repeatDays.contains(5);

  /// Check if weekends only (6, 7)
  bool get isWeekends =>
      repeatDays.length == 2 &&
      repeatDays.contains(6) &&
      repeatDays.contains(7);

  /// Human-readable repeat description
  String get repeatSummary {
    if (repeatDays.isEmpty) {
      return 'Once';
    }
    if (isEveryDay) {
      return 'Every day';
    }
    if (isWeekdays) {
      return 'Weekdays (Mon-Fri)';
    }
    if (isWeekends) {
      return 'Weekends (Sat-Sun)';
    }

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = List<int>.from(repeatDays)..sort();
    return sorted.map((d) => dayNames[d - 1]).join(', ');
  }

  /// Calculates the next DateTime this alarm should trigger from [fromDateTime]
  DateTime getNextTriggerDateTime([DateTime? fromDateTime]) {
    final now = fromDateTime ?? DateTime.now();
    final todayAlarm = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      0,
    );

    if (repeatDays.isEmpty) {
      // Once alarm
      if (todayAlarm.isAfter(now)) {
        return todayAlarm;
      } else {
        // Schedule for tomorrow same time
        return todayAlarm.add(const Duration(days: 1));
      }
    }

    // Repeating alarm
    for (int dayOffset = 0; dayOffset <= 7; dayOffset++) {
      final candidateDate = now.add(Duration(days: dayOffset));
      final candidateAlarm = DateTime(
        candidateDate.year,
        candidateDate.month,
        candidateDate.day,
        time.hour,
        time.minute,
        0,
      );

      final weekday = candidateDate.weekday; // 1 = Mon ... 7 = Sun
      if (repeatDays.contains(weekday)) {
        if (candidateAlarm.isAfter(now)) {
          return candidateAlarm;
        }
      }
    }

    // Fallback: 7 days from next matching
    final sorted = List<int>.from(repeatDays)..sort();
    final firstDay = sorted.first;
    int daysUntil = (firstDay - now.weekday + 7) % 7;
    if (daysUntil == 0) daysUntil = 7;
    return DateTime(
      now.year,
      now.month,
      now.day + daysUntil,
      time.hour,
      time.minute,
      0,
    );
  }

  /// Formatted 12-hour or 24-hour time representation
  String formattedTime() {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
  }

  Alarm copyWith({
    String? id,
    TimeOfDay? time,
    bool? enabled,
    List<int>? repeatDays,
    String? sound,
    String? label,
  }) {
    return Alarm(
      id: id ?? this.id,
      time: time ?? this.time,
      enabled: enabled ?? this.enabled,
      repeatDays: repeatDays ?? this.repeatDays,
      sound: sound ?? this.sound,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'enabled': enabled,
      'repeatDays': repeatDays,
      'sound': sound,
      'label': label,
    };
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'] as String,
      time: TimeOfDay(
        hour: json['hour'] as int,
        minute: json['minute'] as int,
      ),
      enabled: json['enabled'] as bool? ?? true,
      repeatDays: (json['repeatDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      sound: json['sound'] as String? ?? 'Classic Alarm',
      label: json['label'] as String? ?? 'Wake Up',
    );
  }
}

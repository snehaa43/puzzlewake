import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/alarm.dart';
import 'package:flutter_application_1/services/alarm_service.dart';
import 'package:flutter_application_1/services/notification_service.dart';
import 'package:flutter_application_1/services/puzzle_service.dart';
import 'package:flutter_application_1/services/sound_service.dart';
import 'package:flutter_application_1/services/storage_service.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Alarm getNextTriggerDateTime calculates correct future trigger and 5-min pre-alarm', () {
    final baseTime = DateTime(2026, 9, 19, 10, 0, 0); // 10:00 AM
    // Alarm set for 10:30 AM
    final alarm = Alarm(
      id: 'test-1',
      time: const TimeOfDay(hour: 10, minute: 30),
      enabled: true,
      label: 'Morning Standup',
    );

    final nextTrigger = alarm.getNextTriggerDateTime(baseTime);
    expect(nextTrigger.hour, 10);
    expect(nextTrigger.minute, 30);
    expect(nextTrigger.day, 19);

    final preAlarm = nextTrigger.subtract(const Duration(minutes: 5));
    expect(preAlarm.hour, 10);
    expect(preAlarm.minute, 25);
    expect(preAlarm.isBefore(nextTrigger), true);
  });

  test('Repeating alarm calculates correct next weekday trigger', () {
    // 2026-09-19 is a Saturday (weekday = 6)
    final saturday = DateTime(2026, 9, 19, 8, 0, 0);
    // Weekday-only alarm (Mon-Fri = 1..5) at 7:00 AM
    final weekdayAlarm = Alarm(
      id: 'weekday-1',
      time: const TimeOfDay(hour: 7, minute: 0),
      enabled: true,
      repeatDays: const [1, 2, 3, 4, 5],
      label: 'Workday Wake',
    );

    final nextTrigger = weekdayAlarm.getNextTriggerDateTime(saturday);
    // Should trigger on Monday (weekday = 1), which is Sep 21
    expect(nextTrigger.weekday, 1);
    expect(nextTrigger.day, 21);
    expect(nextTrigger.hour, 7);
    expect(nextTrigger.minute, 0);
  });

  testWidgets('PuzzleWakeApp renders Home Screen with Sleep Time, Alarms header, and navigation bar',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);
    final soundService = SoundService();
    final puzzleService = PuzzleService();
    final notificationService = NotificationService();
    final alarmService = AlarmService(
      storage: storageService,
      soundService: soundService,
      notificationService: notificationService,
    );

    await tester.pumpWidget(PuzzleWakeApp(
      storageService: storageService,
      soundService: soundService,
      puzzleService: puzzleService,
      alarmService: alarmService,
      notificationService: notificationService,
    ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Sleep Time header
    expect(find.text('Sleep Time'), findsOneWidget);

    // Verify Alarms section header
    expect(find.text('Alarms'), findsOneWidget);

    // Verify Edit button icon exists
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

    // Verify Alarm bottom navigation icon exists
    expect(find.byIcon(Icons.alarm), findsOneWidget);

    // Clean up services and active widget tree
    alarmService.dispose();
    soundService.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}


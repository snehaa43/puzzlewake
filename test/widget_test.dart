import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/alarm_service.dart';
import 'package:flutter_application_1/services/puzzle_service.dart';
import 'package:flutter_application_1/services/sound_service.dart';
import 'package:flutter_application_1/services/storage_service.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('PuzzleWakeApp renders Home Screen with title and Add Alarm button',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);
    final soundService = SoundService();
    final puzzleService = PuzzleService();
    final alarmService = AlarmService(
      storage: storageService,
      soundService: soundService,
    );

    await tester.pumpWidget(PuzzleWakeApp(
      storageService: storageService,
      soundService: soundService,
      puzzleService: puzzleService,
      alarmService: alarmService,
    ));

    await tester.pumpAndSettle();

    // Verify app title
    expect(find.text('PuzzleWake'), findsOneWidget);

    // Verify Add Alarm button
    expect(find.text('Add Alarm'), findsOneWidget);

    // Verify Settings button icon exists
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    // Clean up services and active widget tree
    alarmService.dispose();
    soundService.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}

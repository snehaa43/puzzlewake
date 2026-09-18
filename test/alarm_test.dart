import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/alarm.dart';
import 'package:flutter_application_1/models/puzzle.dart';
import 'package:flutter_application_1/services/puzzle_service.dart';

void main() {
  group('Alarm Model Tests', () {
    test('JSON serialization and deserialization works correctly', () {
      final alarm = Alarm(
        id: 'test-123',
        time: const TimeOfDay(hour: 7, minute: 30),
        enabled: true,
        repeatDays: const [1, 2, 3, 4, 5],
        sound: 'Digital Alarm',
        label: 'Work Days',
      );

      final json = alarm.toJson();
      final fromJson = Alarm.fromJson(json);

      expect(fromJson.id, equals(alarm.id));
      expect(fromJson.time.hour, equals(7));
      expect(fromJson.time.minute, equals(30));
      expect(fromJson.enabled, isTrue);
      expect(fromJson.repeatDays, equals([1, 2, 3, 4, 5]));
      expect(fromJson.sound, equals('Digital Alarm'));
      expect(fromJson.label, equals('Work Days'));
      expect(fromJson.isWeekdays, isTrue);
      expect(fromJson.repeatSummary, equals('Weekdays (Mon-Fri)'));
    });

    test('Repeat summary labels format properly', () {
      final onceAlarm = Alarm(
        id: '1',
        time: const TimeOfDay(hour: 8, minute: 0),
        repeatDays: const [],
      );
      expect(onceAlarm.repeatSummary, equals('Once'));

      final everyDayAlarm = Alarm(
        id: '2',
        time: const TimeOfDay(hour: 8, minute: 0),
        repeatDays: const [1, 2, 3, 4, 5, 6, 7],
      );
      expect(everyDayAlarm.repeatSummary, equals('Every day'));

      final weekendsAlarm = Alarm(
        id: '3',
        time: const TimeOfDay(hour: 8, minute: 0),
        repeatDays: const [6, 7],
      );
      expect(weekendsAlarm.repeatSummary, equals('Weekends (Sat-Sun)'));

      final customAlarm = Alarm(
        id: '4',
        time: const TimeOfDay(hour: 8, minute: 0),
        repeatDays: const [1, 3, 5],
      );
      expect(customAlarm.repeatSummary, equals('Mon, Wed, Fri'));
    });

    test('Next trigger date calculation handles next-day boundary for once alarm', () {
      final baseDate = DateTime(2026, 9, 18, 10, 0); // 10:00 AM

      // Alarm set for 07:00 AM (already passed today) -> Should trigger tomorrow
      final pastAlarm = Alarm(
        id: 'past',
        time: const TimeOfDay(hour: 7, minute: 0),
        repeatDays: const [],
      );
      final nextTrigger = pastAlarm.getNextTriggerDateTime(baseDate);
      expect(nextTrigger.day, equals(19));
      expect(nextTrigger.hour, equals(7));
      expect(nextTrigger.minute, equals(0));

      // Alarm set for 11:00 AM (upcoming today) -> Should trigger today
      final futureAlarm = Alarm(
        id: 'future',
        time: const TimeOfDay(hour: 11, minute: 0),
        repeatDays: const [],
      );
      final nextFutureTrigger = futureAlarm.getNextTriggerDateTime(baseDate);
      expect(nextFutureTrigger.day, equals(18));
      expect(nextFutureTrigger.hour, equals(11));
      expect(nextFutureTrigger.minute, equals(0));
    });
  });

  group('Puzzle Service and Mechanics Tests', () {
    final puzzleService = PuzzleService();

    test('Generated puzzle has 9 pieces and is not solved initially', () {
      final puzzle = puzzleService.createNewPuzzle();
      expect(puzzle.pieces.length, equals(9));
      expect(puzzle.isSolved, isFalse);
      expect(puzzle.isCompleted, isFalse);
      expect(puzzle.moves, equals(0));
      expect(puzzle.selectedSlot, isNull);
    });

    test('Puzzle piece row and column calculations match 3x3 layout', () {
      const piece0 = PuzzlePiece(originalIndex: 0, currentIndex: 0);
      expect(piece0.originalRow, equals(0));
      expect(piece0.originalCol, equals(0));
      expect(piece0.isCorrect, isTrue);

      const piece4 = PuzzlePiece(originalIndex: 4, currentIndex: 4); // center
      expect(piece4.originalRow, equals(1));
      expect(piece4.originalCol, equals(1));
      expect(piece4.isCorrect, isTrue);

      const piece8 = PuzzlePiece(originalIndex: 8, currentIndex: 2); // misplaced
      expect(piece8.originalRow, equals(2));
      expect(piece8.originalCol, equals(2));
      expect(piece8.isCorrect, isFalse);
    });

    test('Slot tap flow: select piece A -> select piece B -> swap pieces', () {
      final state = PuzzleState(
        imageAsset: 'assets/images/morning.jpg',
        pieces: [1, 0, 2, 3, 4, 5, 6, 7, 8],
      );

      // Step 1: Tap slot 0 (selects slot 0)
      final state1 = puzzleService.handleSlotTap(state, 0);
      expect(state1.selectedSlot, equals(0));
      expect(state1.moves, equals(0));

      // Step 2: Tap slot 1 (swaps slot 0 with slot 1)
      final state2 = puzzleService.handleSlotTap(state1, 1);
      expect(state2.selectedSlot, isNull);
      expect(state2.moves, equals(1));
      expect(state2.pieces, equals([0, 1, 2, 3, 4, 5, 6, 7, 8]));
      expect(state2.isSolved, isTrue);
      expect(state2.isCompleted, isTrue);
    });

    test('Solving validation strictly requires every piece in index order [0..8]', () {
      expect(puzzleService.checkSolved([0, 1, 2, 3, 4, 5, 6, 7, 8]), isTrue);
      expect(puzzleService.checkSolved([1, 0, 2, 3, 4, 5, 6, 7, 8]), isFalse);
      expect(puzzleService.checkSolved([0, 1, 2, 3, 4, 5, 6, 8, 7]), isFalse);
    });
  });
}

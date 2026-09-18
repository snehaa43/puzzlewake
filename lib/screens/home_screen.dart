import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../services/puzzle_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/alarm_card.dart';
import 'alarm_screen.dart';
import 'create_alarm_screen.dart';
import 'settings_screen.dart';

/// Main Home Screen of PuzzleWake.
class HomeScreen extends StatefulWidget {
  final AlarmService alarmService;
  final SoundService soundService;
  final StorageService storageService;
  final PuzzleService puzzleService;
  final ValueChanged<bool> onThemeChanged;

  const HomeScreen({
    super.key,
    required this.alarmService,
    required this.soundService,
    required this.storageService,
    required this.puzzleService,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();

    // Setup global trigger navigation callback
    widget.alarmService.onAlarmTriggered = (alarm) {
      if (mounted) {
        _navigateToAlarmScreen(alarm);
      }
    };

    // Live clock ticker
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    // Check if an alarm is already ringing on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.alarmService.isAlarmRinging &&
          widget.alarmService.activeRingingAlarm != null) {
        _navigateToAlarmScreen(widget.alarmService.activeRingingAlarm!);
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _navigateToAlarmScreen(Alarm alarm) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlarmScreen(
          alarm: alarm,
          alarmService: widget.alarmService,
          puzzleService: widget.puzzleService,
        ),
      ),
    );
  }

  void _openCreateAlarm([Alarm? existing]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateAlarmScreen(
          existingAlarm: existing,
          alarmService: widget.alarmService,
          soundService: widget.soundService,
          storageService: widget.storageService,
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          storageService: widget.storageService,
          soundService: widget.soundService,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final timeFormatter = DateFormat('h:mm');
    final periodFormatter = DateFormat('a');
    final dateFormatter = DateFormat('EEEE, MMM d');

    final timeStr = timeFormatter.format(_currentTime);
    final periodStr = periodFormatter.format(_currentTime);
    final dateStr = dateFormatter.format(_currentTime);

    final nextAlarmInfo = widget.alarmService.getNextAlarmTimeRemaining();

    return ListenableBuilder(
      listenable: widget.alarmService,
      builder: (context, _) {
        final alarms = widget.alarmService.alarms;

        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // --- Modern Morning App Bar ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.extension,
                                color: AppTheme.primaryAmber,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'PuzzleWake',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Quick Test Trigger Button (for instant puzzle testing)
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkSurfaceVariant : AppTheme.lightSurfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 20,
                                  color: AppTheme.primaryAmber,
                                ),
                              ),
                              tooltip: 'Test Alarm & Puzzle',
                              onPressed: () {
                                final testAlarm = alarms.isNotEmpty
                                    ? alarms.first
                                    : Alarm(
                                        id: 'test-alarm',
                                        time: TimeOfDay.now(),
                                        enabled: true,
                                        sound: 'Classic Alarm',
                                      );
                                _navigateToAlarmScreen(testAlarm);
                              },
                            ),
                            const SizedBox(width: 4),
                            // Settings Button (⚙)
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkSurfaceVariant : AppTheme.lightSurfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.settings_outlined,
                                  size: 20,
                                  color: isDark ? Colors.white70 : AppTheme.lightTextPrimary,
                                ),
                              ),
                              tooltip: 'Settings',
                              onPressed: _openSettings,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // --- Live Digital Clock & Morning Banner ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                              : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppTheme.primaryAmber.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryAmber.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Clock Time
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -2,
                                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                periodStr,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryAmber,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Date string: e.g. Friday, Sep 18
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                          if (nextAlarmInfo != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAmber.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.alarm_on,
                                    size: 14,
                                    color: AppTheme.primaryAmber,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    nextAlarmInfo,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryAmber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // --- Alarms Header ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Alarms',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                          ),
                        ),
                        Text(
                          '${alarms.length} total',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- List of Alarms or Empty State ---
                if (alarms.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryAmber.withValues(alpha: 0.1),
                              ),
                              child: const Icon(
                                Icons.alarm_add_outlined,
                                size: 54,
                                color: AppTheme.primaryAmber,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'No Alarms Configured',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + Add Alarm to create your first puzzle-locked alarm.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final alarm = alarms[index];
                        return AlarmCard(
                          alarm: alarm,
                          onToggle: (enabled) {
                            widget.alarmService.toggleAlarm(alarm.id, enabled);
                          },
                          onTap: () => _openCreateAlarm(alarm),
                          onDelete: () {
                            widget.alarmService.deleteAlarm(alarm.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Alarm deleted'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      childCount: alarms.length,
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 100), // Spacing for FAB
                ),
              ],
            ),
          ),

          // --- Prominent + Add Alarm Button ---
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 24),
                label: const Text(
                  'Add Alarm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                onPressed: () => _openCreateAlarm(),
              ),
            ),
          ),
        );
      },
    );
  }
}

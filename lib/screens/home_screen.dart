import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';
import '../services/puzzle_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/alarm_card.dart';
import '../widgets/moon_stars_illustration.dart';
import 'alarm_screen.dart';
import 'create_alarm_screen.dart';
import 'settings_screen.dart';

/// Main Home Screen of PuzzleWake with celestial night theme, hero Create Alarm button,
/// direct theme switcher, and alarm management actions.
class HomeScreen extends StatefulWidget {
  final AlarmService alarmService;
  final SoundService soundService;
  final StorageService storageService;
  final PuzzleService puzzleService;
  final NotificationService notificationService;
  final ValueChanged<bool> onThemeChanged;

  const HomeScreen({
    super.key,
    required this.alarmService,
    required this.soundService,
    required this.storageService,
    required this.puzzleService,
    required this.notificationService,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.storageService.getDarkMode();

    // Setup global trigger navigation callback
    widget.alarmService.onAlarmTriggered = (alarm) {
      if (mounted) {
        _navigateToAlarmScreen(alarm);
      }
    };

    // Listen for notification taps
    widget.notificationService.onAlarmNotificationTriggered = (alarmId) {
      if (mounted) {
        widget.alarmService.triggerAlarmById(alarmId);
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
          onThemeChanged: (isDark) {
            setState(() {
              _isDarkMode = isDark;
            });
            widget.onThemeChanged(isDark);
          },
        ),
      ),
    );
  }

  Future<void> _toggleTheme() async {
    final newMode = !_isDarkMode;
    setState(() {
      _isDarkMode = newMode;
    });
    await widget.storageService.setDarkMode(newMode);
    widget.onThemeChanged(newMode);
  }

  /// Summary text of the upcoming alarm
  String? _getNextAlarmSummary() {
    final enabledAlarms = widget.alarmService.alarms.where((a) => a.enabled).toList();
    if (enabledAlarms.isEmpty) return null;

    final now = _currentTime;
    DateTime? earliest;
    Alarm? nextAlarm;

    for (final alarm in enabledAlarms) {
      final next = alarm.getNextTriggerDateTime(now);
      if (earliest == null || next.isBefore(earliest)) {
        earliest = next;
        nextAlarm = alarm;
      }
    }

    if (earliest == null || nextAlarm == null) return null;

    final diff = earliest.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    String timeDiff;
    if (hours == 0 && minutes == 0) {
      timeDiff = 'in < 1 min';
    } else if (hours == 0) {
      timeDiff = 'in $minutes min';
    } else if (minutes == 0) {
      timeDiff = 'in $hours hr';
    } else {
      timeDiff = 'in $hours hr $minutes min';
    }

    final hourStr = nextAlarm.time.hour.toString().padLeft(2, '0');
    final minStr = nextAlarm.time.minute.toString().padLeft(2, '0');
    return '$hourStr:$minStr ($timeDiff)';
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1E1033);
    final textSecondary = _isDarkMode ? const Color(0xFFA092B3) : const Color(0xFF6B5880);
    final iconColor = _isDarkMode ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA);

    return ListenableBuilder(
      listenable: widget.alarmService,
      builder: (context, _) {
        final alarms = widget.alarmService.alarms;
        final nextAlarmText = _getNextAlarmSummary();

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.getBackgroundGradient(_isDarkMode),
            ),
            child: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // --- 1. Top Header Bar (Title, Working Theme Toggle & Settings) ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isDarkMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                                color: const Color(0xFFFFD54F),
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'PuzzleWake',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Working Theme Toggle Button (Sun / Moon)
                              IconButton(
                                icon: Icon(
                                  _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                  color: _isDarkMode ? const Color(0xFFFFD54F) : const Color(0xFF7E22CE),
                                  size: 24,
                                ),
                                tooltip: _isDarkMode ? 'Switch to Light Theme' : 'Switch to Dark Theme',
                                onPressed: _toggleTheme,
                              ),
                              // Settings Button
                              IconButton(
                                icon: Icon(
                                  Icons.settings_outlined,
                                  color: iconColor,
                                  size: 22,
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

                  // --- 2. Crescent Moon & Stars Illustration ---
                  const SliverToBoxAdapter(
                    child: Center(
                      child: MoonStarsIllustration(size: 190),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 12),
                  ),

                  // --- 3. Hero "Create Alarm" Button ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => _openCreateAlarm(),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            decoration: BoxDecoration(
                              gradient: _isDarkMode
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF3B245D),
                                        Color(0xFF25163D),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFFFFFFFF),
                                        Color(0xFFFAF5FF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _isDarkMode ? const Color(0xFF8E61BE) : const Color(0xFFDDD0EE),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _isDarkMode
                                      ? const Color(0xFF8E61BE).withValues(alpha: 0.25)
                                      : const Color(0xFF9333EA).withValues(alpha: 0.08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Glowing Circular Plus Icon
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFD8B4FE), Color(0xFFAC70F7)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFAC70F7).withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.alarm_add_rounded,
                                    color: Color(0xFF1E1033),
                                    size: 26,
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Center: Text Titles
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Create Alarm',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: textPrimary,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        nextAlarmText != null
                                            ? 'Next: $nextAlarmText'
                                            : 'Tap to set time & puzzle challenge',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: _isDarkMode ? const Color(0xFFC7B8DA) : const Color(0xFF6B5880),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Right Arrow Action Badge
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode ? const Color(0xFF4A326E) : const Color(0xFFF3E8FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: _isDarkMode ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA),
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),

                  // --- 4. "Alarms" Section Title with Count Badge ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Alarms',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (alarms.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: _isDarkMode ? const Color(0xFF33204E) : const Color(0xFFEDE4F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isDarkMode ? const Color(0xFF533878) : const Color(0xFFDACBED),
                                ),
                              ),
                              child: Text(
                                '${alarms.length} ${alarms.length == 1 ? 'alarm' : 'alarms'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isDarkMode ? const Color(0xFFD8B4FE) : const Color(0xFF7E22CE),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // --- 5. Alarms List or Empty State ---
                  if (alarms.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: _isDarkMode ? const Color(0xFF2B1C42) : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _isDarkMode ? const Color(0xFF432D65) : const Color(0xFFE2D6F3),
                                  ),
                                ),
                                child: Icon(
                                  Icons.alarm_outlined,
                                  size: 40,
                                  color: iconColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No alarms created yet',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap "+ Create Alarm" above to set your first wake-up puzzle!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 13,
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
                            },
                          );
                        },
                        childCount: alarms.length,
                      ),
                    ),

                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 36),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

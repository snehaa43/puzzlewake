import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/alarm.dart';
import '../models/puzzle.dart';
import '../services/alarm_service.dart';
import '../services/puzzle_service.dart';
import '../theme/app_theme.dart';
import '../widgets/puzzle_board.dart';

/// Dedicated Full-Screen Alarm Ringing and Jigsaw Puzzle Screen.
/// The alarm sound and vibration loop continuously until the puzzle is solved.
class AlarmScreen extends StatefulWidget {
  final Alarm alarm;
  final AlarmService alarmService;
  final PuzzleService puzzleService;

  const AlarmScreen({
    super.key,
    required this.alarm,
    required this.alarmService,
    required this.puzzleService,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late PuzzleState _puzzleState;
  late ConfettiController _confettiController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();
  bool _isSuccessCelebration = false;

  @override
  void initState() {
    super.initState();

    // Initialize 3x3 Puzzle with a random morning image
    _puzzleState = widget.puzzleService.createNewPuzzle();

    // Confetti for success celebration
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));

    // Pulsing bell animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Live digital clock timer
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _onPieceTapped(int slotIndex) {
    if (_isSuccessCelebration) return;

    HapticFeedback.lightImpact();

    setState(() {
      _puzzleState = widget.puzzleService.handleSlotTap(_puzzleState, slotIndex);
    });

    // Check if puzzle is successfully completed
    if (_puzzleState.isSolved && !_isSuccessCelebration) {
      _onPuzzleSolved();
    }
  }

  void _onPuzzleSolved() async {
    setState(() {
      _isSuccessCelebration = true;
    });

    // 1. Immediately silence alarm sound & vibration
    await widget.alarmService.onPuzzleCompleted();

    // 2. Play celebratory explosion
    _confettiController.play();
    HapticFeedback.heavyImpact();
  }

  void _onDismissSuccess() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hourStr = _currentTime.hour == 0
        ? '12'
        : (_currentTime.hour > 12
            ? (_currentTime.hour - 12).toString().padLeft(2, '0')
            : _currentTime.hour.toString().padLeft(2, '0'));
    final minStr = _currentTime.minute.toString().padLeft(2, '0');
    final period = _currentTime.hour >= 12 ? 'PM' : 'AM';

    return PopScope(
      canPop: false, // Prevents backing out of alarm screen without solving puzzle!
      child: Scaffold(
        backgroundColor: const Color(0xFF0D131F),
        body: Stack(
          alignment: Alignment.center,
          children: [
            // Morning dawn background aura
            Positioned(
              top: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryAmber.withValues(alpha: 0.35),
                      AppTheme.coralSunrise.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: _isSuccessCelebration
                  ? _buildSuccessView()
                  : _buildActiveAlarmView(hourStr, minStr, period),
            ),

            // Celebration Confetti Cannon
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  AppTheme.primaryAmber,
                  AppTheme.primarySun,
                  AppTheme.coralSunrise,
                  AppTheme.successGreen,
                  Colors.white,
                  AppTheme.morningSky,
                ],
                numberOfParticles: 35,
                gravity: 0.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Active ringing view with Live Clock, Wake banner, and 3x3 Jigsaw puzzle
  Widget _buildActiveAlarmView(String hourStr, String minStr, String period) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Header: Pulsing Bell & Current Time
                Column(
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryAmber.withValues(alpha: 0.2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryAmber.withValues(alpha: 0.4),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.alarm_on,
                          color: AppTheme.primaryAmber,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Live digital clock display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$hourStr:$minStr',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          period,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryAmber,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),
                    const Text(
                      'GOOD MORNING 🌅',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: AppTheme.primarySun,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Complete the puzzle to stop the alarm.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Center: 3x3 Jigsaw Puzzle Board
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340, maxHeight: 340),
                  child: PuzzleBoard(
                    state: _puzzleState,
                    onPieceTapped: _onPieceTapped,
                  ),
                ),

                const SizedBox(height: 16),

                // Bottom Footer: Instructions & Progress
                Column(
                  children: [
                    // Progress Indicator Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _puzzleState.selectedSlot != null
                                ? Icons.touch_app
                                : Icons.extension_outlined,
                            size: 16,
                            color: AppTheme.primaryAmber,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _puzzleState.selectedSlot != null
                                ? 'Tap another piece to swap!'
                                : '${_puzzleState.correctCount}/9 pieces in place',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Solve the puzzle to turn off the alarm.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Success celebration screen when puzzle is solved and alarm silenced
  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Starburst Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.successGreen.withValues(alpha: 0.2),
                border: Border.all(color: AppTheme.successGreen, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.successGreen.withValues(alpha: 0.4),
                    blurRadius: 32,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppTheme.successGreen,
                size: 72,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              '🎉 PUZZLE SOLVED!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Good morning! ☀️',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primarySun,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Alarm stopped successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 36),

            // Solved puzzle preview
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 140,
                height: 140,
                child: Image.asset(
                  _puzzleState.imageAsset,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Prominent [ Done ] Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 4,
                ),
                onPressed: _onDismissSuccess,
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

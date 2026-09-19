import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

/// Interactive Sound Selector list with play/preview buttons styled for adaptive theme.
class SoundSelector extends StatelessWidget {
  final String selectedSound;
  final ValueChanged<String> onSoundSelected;
  final SoundService soundService;
  final double volume;

  const SoundSelector({
    super.key,
    required this.selectedSound,
    required this.onSoundSelected,
    required this.soundService,
    this.volume = 0.8,
  });

  IconData _getSoundIcon(String soundName) {
    switch (soundName) {
      case 'Classic Alarm':
        return Icons.alarm;
      case 'Digital Alarm':
        return Icons.timer_outlined;
      case 'Morning Bell':
        return Icons.notifications_active_outlined;
      case 'Gentle Wake':
        return Icons.bedtime_outlined;
      case 'Wake Up':
        return Icons.wb_sunny_outlined;
      default:
        return Icons.music_note_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sounds = SoundService.availableSounds;

    return Column(
      children: sounds.map((soundName) {
        final isSelected = selectedSound == soundName;
        final isPreviewing = soundService.currentPreviewingSound == soundName;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                onSoundSelected(soundName);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? (isSelected ? const Color(0xFF382356) : const Color(0xFF241938))
                      : (isSelected ? const Color(0xFFF3E8FF) : Colors.white),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? (isSelected ? const Color(0xFFBE8DF1) : const Color(0xFF382952))
                        : (isSelected ? const Color(0xFF9333EA) : const Color(0xFFE2D6F3)),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    // Radio / Selected indicator
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isDark
                          ? (isSelected ? const Color(0xFFBE8DF1) : Colors.white38)
                          : (isSelected ? const Color(0xFF9333EA) : const Color(0xFFB5A9C5)),
                      size: 20,
                    ),
                    const SizedBox(width: 12),

                    // Sound Icon
                    Icon(
                      _getSoundIcon(soundName),
                      color: isDark
                          ? (isSelected ? const Color(0xFFD8B4FE) : const Color(0xFFA092B3))
                          : (isSelected ? const Color(0xFF7E22CE) : const Color(0xFF6B5880)),
                      size: 22,
                    ),
                    const SizedBox(width: 12),

                    // Sound Name
                    Expanded(
                      child: Text(
                        soundName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isDark
                              ? (isSelected ? Colors.white : const Color(0xFFA092B3))
                              : (isSelected ? const Color(0xFF1E1033) : const Color(0xFF6B5880)),
                        ),
                      ),
                    ),

                    // Preview Button (Play / Stop)
                    IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isPreviewing ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                          key: ValueKey(isPreviewing),
                          color: isPreviewing
                              ? AppTheme.alertRed
                              : (isDark ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA)),
                          size: 32,
                        ),
                      ),
                      tooltip: isPreviewing ? 'Stop Preview' : 'Preview Sound',
                      onPressed: () {
                        soundService.previewSound(soundName, volume: volume);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

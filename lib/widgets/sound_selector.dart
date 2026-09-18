import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

/// Interactive Sound Selector list with play/preview buttons.
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
        return Icons.nature_people_outlined;
      case 'Wake Up':
        return Icons.wb_sunny_outlined;
      default:
        return Icons.music_note_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                onSoundSelected(soundName);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryAmber.withValues(alpha: isDark ? 0.2 : 0.1)
                      : (isDark ? AppTheme.darkSurfaceVariant.withValues(alpha: 0.5) : AppTheme.lightSurfaceVariant.withValues(alpha: 0.6)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryAmber
                        : (isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Radio / Selected indicator
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? AppTheme.primaryAmber : (isDark ? Colors.white38 : Colors.black38),
                      size: 20,
                    ),
                    const SizedBox(width: 12),

                    // Sound Icon
                    Icon(
                      _getSoundIcon(soundName),
                      color: isSelected ? AppTheme.primaryAmber : (isDark ? Colors.white70 : AppTheme.lightTextPrimary),
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
                          color: isSelected
                              ? (isDark ? Colors.white : AppTheme.lightTextPrimary)
                              : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextPrimary),
                        ),
                      ),
                    ),

                    // Preview Button (Play / Stop)
                    IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isPreviewing ? Icons.stop_circle : Icons.play_circle_fill,
                          key: ValueKey(isPreviewing),
                          color: isPreviewing ? AppTheme.alertRed : AppTheme.primaryAmber,
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

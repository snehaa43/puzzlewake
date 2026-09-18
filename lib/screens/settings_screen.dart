import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sound_selector.dart';

/// Dedicated Settings Page limited strictly to the 4 requested settings:
/// 1. Alarm Volume
/// 2. Vibration
/// 3. Default Alarm Sound
/// 4. Dark Mode
class SettingsScreen extends StatefulWidget {
  final StorageService storageService;
  final SoundService soundService;
  final ValueChanged<bool> onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.storageService,
    required this.soundService,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _volume;
  late bool _vibrationEnabled;
  late String _defaultSound;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _volume = widget.storageService.getAlarmVolume();
    _vibrationEnabled = widget.storageService.getVibrationEnabled();
    _defaultSound = widget.storageService.getDefaultSound();
    _isDarkMode = widget.storageService.getDarkMode();
  }

  @override
  void dispose() {
    widget.soundService.stopPreview();
    super.dispose();
  }

  Future<void> _updateVolume(double value) async {
    setState(() {
      _volume = value;
    });
    await widget.storageService.setAlarmVolume(value);
    await widget.soundService.setAlarmVolume(value);
  }

  Future<void> _updateVibration(bool value) async {
    setState(() {
      _vibrationEnabled = value;
    });
    await widget.storageService.setVibrationEnabled(value);
  }

  Future<void> _updateDefaultSound(String sound) async {
    setState(() {
      _defaultSound = sound;
    });
    await widget.storageService.setDefaultSound(sound);
  }

  Future<void> _updateDarkMode(bool value) async {
    setState(() {
      _isDarkMode = value;
    });
    await widget.storageService.setDarkMode(value);
    widget.onThemeChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // --- 1. ALARM VOLUME ---
            _buildSectionHeader('Alarm Volume', Icons.volume_up_outlined),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _volume == 0
                            ? Icons.volume_off
                            : (_volume < 0.5 ? Icons.volume_down : Icons.volume_up),
                        color: AppTheme.primaryAmber,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          onChanged: _updateVolume,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(_volume * 100).round()}%',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // --- 2. VIBRATION ---
            _buildSectionHeader('Vibration', Icons.vibration),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vibration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vibrate while alarm is ringing',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _vibrationEnabled,
                    onChanged: _updateVibration,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // --- 3. DEFAULT ALARM SOUND ---
            _buildSectionHeader('Default Alarm Sound', Icons.music_note_outlined),
            const SizedBox(height: 12),
            SoundSelector(
              selectedSound: _defaultSound,
              onSoundSelected: _updateDefaultSound,
              soundService: widget.soundService,
              volume: _volume,
            ),

            const SizedBox(height: 28),

            // --- 4. DARK MODE ---
            _buildSectionHeader('Dark Mode', Icons.dark_mode_outlined),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dark Mode',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isDarkMode ? 'Dark morning theme active' : 'Light sunrise theme active',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isDarkMode,
                    onChanged: _updateDarkMode,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryAmber),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}

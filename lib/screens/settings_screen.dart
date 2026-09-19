import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sound_selector.dart';

/// Dedicated Settings Page styled with adaptive light/dark celestial palette.
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
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1E1033);
    final textSecondary = _isDarkMode ? const Color(0xFFA092B3) : const Color(0xFF6B5880);
    final cardBg = _isDarkMode ? const Color(0xFF241938) : Colors.white;
    final cardBorder = _isDarkMode ? const Color(0xFF382952) : const Color(0xFFE2D6F3);
    final iconColor = _isDarkMode ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getBackgroundGradient(_isDarkMode),
        ),
        child: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // --- 1. ALARM VOLUME ---
              _buildSectionHeader('Alarm Volume', Icons.volume_up_rounded, iconColor, textPrimary),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: _isDarkMode
                          ? Colors.black.withValues(alpha: 0.15)
                          : const Color(0xFF7C3AED).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _volume == 0
                              ? Icons.volume_off_rounded
                              : (_volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
                          color: iconColor,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: _volume,
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            activeColor: _isDarkMode ? const Color(0xFFBE8DF1) : const Color(0xFF9333EA),
                            inactiveColor: _isDarkMode ? const Color(0xFF3B285A) : const Color(0xFFE4D7F5),
                            onChanged: _updateVolume,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(_volume * 100).round()}%',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // --- 2. VIBRATION ---
              _buildSectionHeader('Vibration', Icons.vibration_rounded, iconColor, textPrimary),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: _isDarkMode
                          ? Colors.black.withValues(alpha: 0.15)
                          : const Color(0xFF7C3AED).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vibrate while alarm is ringing',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _vibrationEnabled,
                      activeTrackColor: _isDarkMode ? const Color(0xFFBE8DF1) : const Color(0xFF9333EA),
                      inactiveTrackColor: _isDarkMode ? const Color(0xFF382752) : const Color(0xFFE4D7F5),
                      activeThumbColor: Colors.white,
                      onChanged: _updateVibration,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // --- 3. DEFAULT ALARM SOUND ---
              _buildSectionHeader('Default Alarm Sound', Icons.music_note_rounded, iconColor, textPrimary),
              const SizedBox(height: 12),
              SoundSelector(
                selectedSound: _defaultSound,
                onSoundSelected: _updateDefaultSound,
                soundService: widget.soundService,
                volume: _volume,
              ),

              const SizedBox(height: 28),

              // --- 4. DARK / LIGHT THEME TOGGLE ---
              _buildSectionHeader(
                _isDarkMode ? 'Night Mode' : 'Light Mode',
                _isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                iconColor,
                textPrimary,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: _isDarkMode
                          ? Colors.black.withValues(alpha: 0.15)
                          : const Color(0xFF7C3AED).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isDarkMode ? 'Celestial Night Theme' : 'Celestial Dawn Theme',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isDarkMode
                                ? 'Dark purple sky with glowing crescent moon'
                                : 'Fresh lavender dawn with bright elements',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isDarkMode,
                      activeTrackColor: const Color(0xFFBE8DF1),
                      inactiveTrackColor: const Color(0xFFE4D7F5),
                      activeThumbColor: Colors.white,
                      inactiveThumbColor: const Color(0xFF9333EA),
                      onChanged: _updateDarkMode,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color iconColor, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

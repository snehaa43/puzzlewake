import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Service responsible for alarm sounds, looping audio, sound preview, volume, and vibration.
class SoundService {
  static const Map<String, String> soundAssetMap = {
    'Classic Alarm': 'sounds/classic_alarm.mp3',
    'Digital Alarm': 'sounds/digital_alarm.mp3',
    'Morning Bell': 'sounds/morning_bell.mp3',
    'Gentle Wake': 'sounds/gentle_wake.mp3',
    'Wake Up': 'sounds/wake_up.mp3',
  };

  static List<String> get availableSounds => soundAssetMap.keys.toList();

  final AudioPlayer _alarmPlayer = AudioPlayer();
  final AudioPlayer _previewPlayer = AudioPlayer();

  String? _currentPreviewingSound;
  String? _activeAlarmSound;
  bool _isPlayingAlarm = false;
  Timer? _previewTimer;
  Timer? _vibrationTimer;

  bool get isPlayingAlarm => _isPlayingAlarm;
  String? get currentPreviewingSound => _currentPreviewingSound;
  String? get activeAlarmSound => _activeAlarmSound;

  SoundService() {
    _alarmPlayer.setReleaseMode(ReleaseMode.loop);
    _previewPlayer.setReleaseMode(ReleaseMode.stop);

    _previewPlayer.onPlayerComplete.listen((_) {
      _currentPreviewingSound = null;
    });
  }

  /// Start playing the alarm sound in an infinite loop until explicitly stopped
  Future<void> playAlarmSound(
    String soundName, {
    double volume = 0.8,
    bool enableVibration = true,
  }) async {
    // Stop any active preview first
    await stopPreview();

    final assetPath = soundAssetMap[soundName] ?? soundAssetMap['Classic Alarm']!;
    _activeAlarmSound = soundName;
    _isPlayingAlarm = true;

    try {
      await _alarmPlayer.stop();
      await _alarmPlayer.setVolume(volume.clamp(0.0, 1.0));
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
      await _alarmPlayer.play(AssetSource(assetPath));
    } catch (e) {
      // Audio fallback handling
    }

    if (enableVibration) {
      startVibration();
    }
  }

  /// Stop active alarm ringing and vibration immediately
  Future<void> stopAlarmSound() async {
    _isPlayingAlarm = false;
    _activeAlarmSound = null;
    stopVibration();

    try {
      await _alarmPlayer.stop();
    } catch (_) {}
  }

  /// Preview a sound in Settings or Create Alarm screen
  Future<void> previewSound(String soundName, {double volume = 0.8}) async {
    if (_currentPreviewingSound == soundName) {
      // Toggle off if tapping already playing preview
      await stopPreview();
      return;
    }

    await stopPreview();
    final assetPath = soundAssetMap[soundName] ?? soundAssetMap['Classic Alarm']!;
    _currentPreviewingSound = soundName;

    try {
      await _previewPlayer.stop();
      await _previewPlayer.setVolume(volume.clamp(0.0, 1.0));
      await _previewPlayer.setReleaseMode(ReleaseMode.stop);
      await _previewPlayer.play(AssetSource(assetPath));

      // Auto-stop preview after 6 seconds if not manually stopped
      _previewTimer?.cancel();
      _previewTimer = Timer(const Duration(seconds: 6), () {
        stopPreview();
      });
    } catch (_) {
      _currentPreviewingSound = null;
    }
  }

  /// Stop current preview playback
  Future<void> stopPreview() async {
    _previewTimer?.cancel();
    _previewTimer = null;
    _currentPreviewingSound = null;
    try {
      await _previewPlayer.stop();
    } catch (_) {}
  }

  /// Dynamically update volume while playing
  Future<void> setAlarmVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    try {
      await _alarmPlayer.setVolume(clamped);
      await _previewPlayer.setVolume(clamped);
    } catch (_) {}
  }

  /// Vibration loop using standard HapticFeedback / Platform vibration pulses
  void startVibration() {
    stopVibration();
    // Pulse haptics every 700ms
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      HapticFeedback.heavyImpact();
    });
    // Trigger initial pulse immediately
    HapticFeedback.heavyImpact();
  }

  /// Stop vibration loop immediately
  void stopVibration() {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
  }

  /// Dispose audio players
  void dispose() {
    _previewTimer?.cancel();
    _vibrationTimer?.cancel();
    _alarmPlayer.dispose();
    _previewPlayer.dispose();
  }
}

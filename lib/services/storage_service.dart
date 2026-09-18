import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';

/// Service responsible for local persistence of Alarms and Settings.
class StorageService {
  static const String _keyAlarms = 'puzzlewake_alarms';
  static const String _keyAlarmVolume = 'puzzlewake_alarm_volume';
  static const String _keyVibration = 'puzzlewake_vibration_enabled';
  static const String _keyDefaultSound = 'puzzlewake_default_sound';
  static const String _keyDarkMode = 'puzzlewake_dark_mode';
  static const String _keyActiveAlarmId = 'puzzlewake_active_alarm_id';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Alarms Management ---

  /// Load all saved alarms from local storage
  List<Alarm> loadAlarms() {
    final rawJson = _prefs.getString(_keyAlarms);
    if (rawJson == null || rawJson.isEmpty) {
      return _getDefaultInitialAlarms();
    }
    try {
      final List<dynamic> list = jsonDecode(rawJson) as List<dynamic>;
      return list.map((item) => Alarm.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return _getDefaultInitialAlarms();
    }
  }

  /// Save alarms list to local storage
  Future<void> saveAlarms(List<Alarm> alarms) async {
    final list = alarms.map((a) => a.toJson()).toList();
    await _prefs.setString(_keyAlarms, jsonEncode(list));
  }

  /// Default starting alarms for first app launch
  List<Alarm> _getDefaultInitialAlarms() {
    return [
      Alarm(
        id: 'default-alarm-1',
        time: TimeOfDay(hour: 7, minute: 0),
        enabled: true,
        repeatDays: const [1, 2, 3, 4, 5, 6, 7], // Every day
        sound: 'Classic Alarm',
        label: 'Good Morning',
      ),
      Alarm(
        id: 'default-alarm-2',
        time: TimeOfDay(hour: 8, minute: 30),
        enabled: false,
        repeatDays: const [], // Once
        sound: 'Gentle Wake',
        label: 'Weekend Rise',
      ),
    ];
  }

  // --- Settings Management ---

  /// Alarm Volume (0.0 to 1.0, default 0.8)
  double getAlarmVolume() {
    return _prefs.getDouble(_keyAlarmVolume) ?? 0.8;
  }

  Future<void> setAlarmVolume(double volume) async {
    await _prefs.setDouble(_keyAlarmVolume, volume.clamp(0.0, 1.0));
  }

  /// Vibration Enabled (default: true)
  bool getVibrationEnabled() {
    return _prefs.getBool(_keyVibration) ?? true;
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    await _prefs.setBool(_keyVibration, enabled);
  }

  /// Default Sound (default: 'Classic Alarm')
  String getDefaultSound() {
    return _prefs.getString(_keyDefaultSound) ?? 'Classic Alarm';
  }

  Future<void> setDefaultSound(String sound) async {
    await _prefs.setString(_keyDefaultSound, sound);
  }

  /// Dark Mode preference (default: false)
  bool getDarkMode() {
    return _prefs.getBool(_keyDarkMode) ?? false;
  }

  Future<void> setDarkMode(bool isDark) async {
    await _prefs.setBool(_keyDarkMode, isDark);
  }

  /// Active ringing alarm ID (null when no alarm is actively ringing)
  String? getActiveAlarmId() {
    return _prefs.getString(_keyActiveAlarmId);
  }

  Future<void> setActiveAlarmId(String? id) async {
    if (id == null) {
      await _prefs.remove(_keyActiveAlarmId);
    } else {
      await _prefs.setString(_keyActiveAlarmId, id);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sound_selector.dart';

/// Screen for creating a new alarm or editing an existing alarm.
class CreateAlarmScreen extends StatefulWidget {
  final Alarm? existingAlarm;
  final AlarmService alarmService;
  final SoundService soundService;
  final StorageService storageService;

  const CreateAlarmScreen({
    super.key,
    this.existingAlarm,
    required this.alarmService,
    required this.soundService,
    required this.storageService,
  });

  @override
  State<CreateAlarmScreen> createState() => _CreateAlarmScreenState();
}

class _CreateAlarmScreenState extends State<CreateAlarmScreen> {
  late TimeOfDay _selectedTime;
  late List<int> _selectedDays;
  late String _selectedSound;
  late TextEditingController _labelController;

  final List<String> _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAlarm;
    if (existing != null) {
      _selectedTime = existing.time;
      _selectedDays = List<int>.from(existing.repeatDays);
      _selectedSound = existing.sound;
      _labelController = TextEditingController(text: existing.label);
    } else {
      // Default to 07:00 AM or next hour
      final now = DateTime.now();
      _selectedTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
      _selectedDays = [1, 2, 3, 4, 5, 6, 7]; // Default Every day
      _selectedSound = widget.storageService.getDefaultSound();
      _labelController = TextEditingController(text: 'Wake Up');
    }
  }

  @override
  void dispose() {
    widget.soundService.stopPreview();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _toggleDay(int dayNumber) {
    setState(() {
      if (_selectedDays.contains(dayNumber)) {
        _selectedDays.remove(dayNumber);
      } else {
        _selectedDays.add(dayNumber);
        _selectedDays.sort();
      }
    });
  }

  void _setRepeatPreset(List<int> days) {
    setState(() {
      _selectedDays = List<int>.from(days);
    });
  }

  Future<void> _saveAlarm() async {
    final isEditing = widget.existingAlarm != null;
    final alarm = Alarm(
      id: isEditing ? widget.existingAlarm!.id : const Uuid().v4(),
      time: _selectedTime,
      enabled: true,
      repeatDays: _selectedDays,
      sound: _selectedSound,
      label: _labelController.text.trim().isEmpty ? 'Wake Up' : _labelController.text.trim(),
    );

    if (isEditing) {
      await widget.alarmService.updateAlarm(alarm);
    } else {
      await widget.alarmService.addAlarm(alarm);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Alarm updated' : 'Alarm set for ${_formatTime(_selectedTime)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.primaryAmber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final min = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.existingAlarm != null;

    final hourStr = _selectedTime.hour == 0
        ? '12'
        : (_selectedTime.hour > 12
            ? (_selectedTime.hour - 12).toString().padLeft(2, '0')
            : _selectedTime.hour.toString().padLeft(2, '0'));
    final minStr = _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.hour >= 12 ? 'PM' : 'AM';

    final isEveryDay = _selectedDays.length == 7;
    final isOnce = _selectedDays.isEmpty;
    final isWeekdays = _selectedDays.length == 5 &&
        [1, 2, 3, 4, 5].every((d) => _selectedDays.contains(d));

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Alarm' : 'Set Alarm'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // --- Time Picker Display Card ---
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [AppTheme.darkSurfaceVariant, AppTheme.darkSurface]
                              : [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.primaryAmber.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$hourStr:$minStr',
                                style: TextStyle(
                                  fontSize: 60,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -2,
                                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                period,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryAmber,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.touch_app_outlined,
                                size: 16,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tap to change time',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // --- Repeat Section ---
                  Text(
                    'Repeat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick presets: Once, Every day, Weekdays
                  Row(
                    children: [
                      _buildPresetChip('Once', isOnce, () => _setRepeatPreset([])),
                      const SizedBox(width: 8),
                      _buildPresetChip('Every day', isEveryDay, () => _setRepeatPreset([1, 2, 3, 4, 5, 6, 7])),
                      const SizedBox(width: 8),
                      _buildPresetChip('Weekdays', isWeekdays, () => _setRepeatPreset([1, 2, 3, 4, 5])),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Individual Day Chips (Mon .. Sun)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final dayNum = index + 1; // 1 = Mon ... 7 = Sun
                      final isSelected = _selectedDays.contains(dayNum);
                      return GestureDetector(
                        onTap: () => _toggleDay(dayNum),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppTheme.primaryAmber
                                : (isDark ? AppTheme.darkSurfaceVariant : AppTheme.lightSurfaceVariant),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryAmber
                                  : (isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _dayLabels[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextPrimary),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  // --- Alarm Sound Section ---
                  Text(
                    'Alarm Sound',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SoundSelector(
                    selectedSound: _selectedSound,
                    onSoundSelected: (sound) {
                      setState(() {
                        _selectedSound = sound;
                      });
                    },
                    soundService: widget.soundService,
                    volume: widget.storageService.getAlarmVolume(),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),

            // --- Set Alarm Prominent CTA Button ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveAlarm,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.alarm_on, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        isEditing ? 'Save Changes' : 'Set Alarm',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, bool isSelected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryAmber.withValues(alpha: isDark ? 0.25 : 0.15)
                : (isDark ? AppTheme.darkSurfaceVariant : AppTheme.lightSurfaceVariant),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryAmber
                  : (isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? AppTheme.primaryAmber
                  : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

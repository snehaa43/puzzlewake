import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sound_selector.dart';

/// Screen for creating a new alarm or editing an existing alarm with light/dark theme adaptability.
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
      // Default to 08:00 AM or next hour
      final now = DateTime.now();
      _selectedTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
      _selectedDays = [1, 2, 3, 4, 5]; // Default Weekdays Mon-Fri
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFFC084FC),
                    onPrimary: Color(0xFF1E1035),
                    surface: Color(0xFF241938),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF9333EA),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF1E1033),
                  ),
          ),
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
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF9333EA),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDelete() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF241938) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? const Color(0xFF4A3468) : const Color(0xFFE2D6F3),
            width: 1,
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF6B6B), size: 26),
            const SizedBox(width: 10),
            Text(
              'Delete Alarm?',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E1033),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this ${_formatTime(_selectedTime)} alarm?',
          style: TextStyle(
            color: isDark ? const Color(0xFFD1C5E2) : const Color(0xFF5B4A70),
            fontSize: 14,
          ),
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? const Color(0xFFA092B3) : const Color(0xFF7A6B8F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.existingAlarm != null && mounted) {
      await widget.alarmService.deleteAlarm(widget.existingAlarm!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Alarm deleted',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: const Color(0xFF8B3A3A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final min = time.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E1033);
    final textSecondary = isDark ? const Color(0xFFA092B3) : const Color(0xFF6B5880);
    final iconColor = isDark ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA);

    final isEditing = widget.existingAlarm != null;
    final hourStr = _selectedTime.hour.toString().padLeft(2, '0');
    final minStr = _selectedTime.minute.toString().padLeft(2, '0');

    final isEveryDay = _selectedDays.length == 7;
    final isOnce = _selectedDays.isEmpty;
    final isWeekdays = _selectedDays.length == 5 &&
        [1, 2, 3, 4, 5].every((d) => _selectedDays.contains(d));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Alarm' : 'Set Alarm',
          style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF6B6B)),
              tooltip: 'Delete Alarm',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getBackgroundGradient(isDark),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // --- Time Picker Display Card ---
                    InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: isDark
                              ? const LinearGradient(
                                  colors: [Color(0xFF2C1E44), Color(0xFF201533)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [Colors.white, Color(0xFFFAF5FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isDark ? const Color(0xFF7C559D) : const Color(0xFFD8B4FE),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? const Color(0xFF7C559D).withValues(alpha: 0.15)
                                  : const Color(0xFF9333EA).withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                                    fontSize: 64,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -2,
                                    color: textPrimary,
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
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Tap to change time',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Quick Time Preset Chips: +5 min, +15 min, +30 min
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildQuickTimeChip('+5 min', isDark, () {
                            final target = DateTime.now().add(const Duration(minutes: 5));
                            setState(() {
                              _selectedTime = TimeOfDay(hour: target.hour, minute: target.minute);
                            });
                          }),
                          const SizedBox(width: 8),
                          _buildQuickTimeChip('+15 min', isDark, () {
                            final target = DateTime.now().add(const Duration(minutes: 15));
                            setState(() {
                              _selectedTime = TimeOfDay(hour: target.hour, minute: target.minute);
                            });
                          }),
                          const SizedBox(width: 8),
                          _buildQuickTimeChip('+30 min', isDark, () {
                            final target = DateTime.now().add(const Duration(minutes: 30));
                            setState(() {
                              _selectedTime = TimeOfDay(hour: target.hour, minute: target.minute);
                            });
                          }),
                          const SizedBox(width: 8),
                          _buildQuickTimeChip('08:00', isDark, () {
                            setState(() {
                              _selectedTime = const TimeOfDay(hour: 8, minute: 0);
                            });
                          }),
                          const SizedBox(width: 8),
                          _buildQuickTimeChip('18:00', isDark, () {
                            setState(() {
                              _selectedTime = const TimeOfDay(hour: 18, minute: 0);
                            });
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- Alarm Label Section ---
                    Text(
                      'Alarm Label',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _labelController,
                      style: TextStyle(color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g. Wake Up, Work, Nap',
                        hintStyle: TextStyle(color: textSecondary),
                        prefixIcon: Icon(Icons.label_outline_rounded, color: iconColor),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF241938) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF382952) : const Color(0xFFE2D6F3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF382952) : const Color(0xFFE2D6F3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFFBE8DF1) : const Color(0xFF9333EA),
                            width: 1.5,
                          ),
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
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick presets: Once, Every day, Weekdays
                    Row(
                      children: [
                        _buildPresetChip('Once', isOnce, isDark, () => _setRepeatPreset([])),
                        const SizedBox(width: 8),
                        _buildPresetChip('Every day', isEveryDay, isDark, () => _setRepeatPreset([1, 2, 3, 4, 5, 6, 7])),
                        const SizedBox(width: 8),
                        _buildPresetChip('Mon-Fri', isWeekdays, isDark, () => _setRepeatPreset([1, 2, 3, 4, 5])),
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
                                  ? (isDark ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA))
                                  : (isDark ? const Color(0xFF241938) : Colors.white),
                              border: Border.all(
                                color: isSelected
                                    ? (isDark ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA))
                                    : (isDark ? const Color(0xFF382952) : const Color(0xFFE2D6F3)),
                              ),
                              boxShadow: [
                                if (!isDark && !isSelected)
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED).withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _dayLabels[index],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? (isDark ? const Color(0xFF1E1033) : Colors.white)
                                    : textSecondary,
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
                        color: textPrimary,
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

                    if (isEditing) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF6B6B),
                            side: BorderSide(
                              color: isDark ? const Color(0xFF6B2838) : const Color(0xFFFCA5A5),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _confirmDelete,
                          icon: const Icon(Icons.delete_outline_rounded, size: 20),
                          label: const Text(
                            'Delete This Alarm',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // --- Save Alarm CTA Button ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B112B) : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF32234A) : const Color(0xFFE5DEEE),
                      width: 1.0,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA),
                      foregroundColor: isDark ? const Color(0xFF1E1035) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _saveAlarm,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.alarm_on_rounded, size: 22),
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
      ),
    );
  }

  Widget _buildPresetChip(String label, bool isSelected, bool isDark, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF3B255B) : const Color(0xFFF3E8FF))
                : (isDark ? const Color(0xFF241938) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? (isDark ? const Color(0xFFBE8DF1) : const Color(0xFF9333EA))
                  : (isDark ? const Color(0xFF382952) : const Color(0xFFE2D6F3)),
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
                  ? (isDark ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA))
                  : (isDark ? const Color(0xFFA092B3) : const Color(0xFF6B5880)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTimeChip(String label, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF241938) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF7C559D) : const Color(0xFFD8B4FE),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 14,
              color: isDark ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E1033),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

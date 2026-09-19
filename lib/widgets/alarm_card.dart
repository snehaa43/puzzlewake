import 'package:flutter/material.dart';
import '../models/alarm.dart';
import '../theme/app_theme.dart';

/// Alarm item card styled with modern celestial aesthetics and direct delete action.
class AlarmCard extends StatelessWidget {
  final Alarm alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  void _showDeleteDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hourStr = alarm.time.hour.toString().padLeft(2, '0');
    final minStr = alarm.time.minute.toString().padLeft(2, '0');

    showDialog(
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
          'Are you sure you want to delete the alarm for $hourStr:$minStr (${alarm.label.isNotEmpty ? alarm.label : "Alarm"})?',
          style: TextStyle(
            color: isDark ? const Color(0xFFD1C5E2) : const Color(0xFF5B4A70),
            fontSize: 14,
          ),
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
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
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete();
            },
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hourStr = alarm.time.hour.toString().padLeft(2, '0');
    final minStr = alarm.time.minute.toString().padLeft(2, '0');

    // Subtitle text: repeat summary (e.g. Mon-Fri, Every day) or label
    String repeatText = alarm.repeatSummary;
    if (alarm.isWeekdays) {
      repeatText = 'Mon-Fri';
    } else if (alarm.isEveryDay) {
      repeatText = 'Every day';
    } else if (alarm.repeatDays.isEmpty) {
      repeatText = 'Once';
    }

    return Dismissible(
      key: Key(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.alertRed.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF241938) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? (alarm.enabled ? const Color(0xFF432F62) : const Color(0xFF32224A))
                : (alarm.enabled ? const Color(0xFFD8B4FE) : const Color(0xFFE8DEFA)),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : const Color(0xFF7C3AED).withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Left Side: Time, Label & Repeat Summary
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$hourStr:$minStr',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: alarm.enabled
                                    ? (isDark ? Colors.white : const Color(0xFF1E1033))
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.38)
                                        : const Color(0xFF9E8FB0)),
                              ),
                            ),
                            if (alarm.label.isNotEmpty && alarm.label != 'Wake Up') ...[
                              const SizedBox(width: 10),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF352452) : const Color(0xFFF1E6FC),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    alarm.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: alarm.enabled
                                          ? (isDark ? const Color(0xFFD8B4FE) : const Color(0xFF7E22CE))
                                          : (isDark
                                              ? Colors.white.withValues(alpha: 0.3)
                                              : const Color(0xFFA092B3)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.repeat_rounded,
                              size: 14,
                              color: alarm.enabled
                                  ? (isDark ? const Color(0xFFA092B3) : const Color(0xFF6B5880))
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : const Color(0xFFB5A9C5)),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                alarm.sound.isNotEmpty ? '$repeatText  •  ${alarm.sound}' : repeatText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: alarm.enabled
                                      ? (isDark ? const Color(0xFFA092B3) : const Color(0xFF6B5880))
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.25)
                                          : const Color(0xFFB5A9C5)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Delete Button
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: isDark ? const Color(0xFFB57070) : const Color(0xFFDC2626),
                      size: 22,
                    ),
                    tooltip: 'Delete Alarm',
                    splashRadius: 22,
                    onPressed: () => _showDeleteDialog(context),
                  ),

                  const SizedBox(width: 2),

                  // Toggle Switch
                  Transform.scale(
                    scale: 0.9,
                    child: Switch(
                      value: alarm.enabled,
                      onChanged: onToggle,
                      activeTrackColor: isDark ? const Color(0xFFBE8DF1) : const Color(0xFF9333EA),
                      inactiveTrackColor: isDark ? const Color(0xFF382752) : const Color(0xFFE4D7F5),
                      inactiveThumbColor: Colors.white,
                      activeThumbColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

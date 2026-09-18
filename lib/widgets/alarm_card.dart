import 'package:flutter/material.dart';
import '../models/alarm.dart';
import '../theme/app_theme.dart';

/// Interactive Material 3 Card representing an Alarm item in the Home list.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hourStr = alarm.time.hour == 0
        ? '12'
        : (alarm.time.hour > 12 ? (alarm.time.hour - 12).toString().padLeft(2, '0') : alarm.time.hour.toString().padLeft(2, '0'));
    final minStr = alarm.time.minute.toString().padLeft(2, '0');
    final period = alarm.time.hour >= 12 ? 'PM' : 'AM';

    final activeColor = AppTheme.primaryAmber;
    final inactiveColor = isDark ? Colors.white38 : Colors.black38;

    return Dismissible(
      key: Key(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.alertRed.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Left: Alarm Time & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time display: 07:00 AM
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$hourStr:$minStr',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: alarm.enabled
                                  ? (isDark ? Colors.white : AppTheme.lightTextPrimary)
                                  : inactiveColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            period,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: alarm.enabled
                                  ? activeColor
                                  : inactiveColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Repeat details & Sound tag
                      Row(
                        children: [
                          Icon(
                            alarm.isRepeating ? Icons.repeat : Icons.alarm,
                            size: 14,
                            color: alarm.enabled
                                ? (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)
                                : inactiveColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            alarm.repeatSummary,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: alarm.enabled
                                  ? (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)
                                  : inactiveColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Sound tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (alarm.enabled ? activeColor : inactiveColor).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.music_note,
                                  size: 12,
                                  color: alarm.enabled ? activeColor : inactiveColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  alarm.sound,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: alarm.enabled ? activeColor : inactiveColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right: ON/OFF Switch
                Switch(
                  value: alarm.enabled,
                  onChanged: onToggle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

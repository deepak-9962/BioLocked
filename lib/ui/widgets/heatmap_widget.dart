import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/luxury_theme.dart';

/// Renders a 7-row (days of week) × 24-col (hours) heatmap.
/// Each cell's intensity shows how many interruptions happened at that day+hour.
class DistractionHeatmapWidget extends StatelessWidget {
  /// Map of "weekday-hour" → count. weekday is 1=Mon … 7=Sun.
  final Map<String, int> data;
  final String title;

  const DistractionHeatmapWidget({
    super.key,
    required this.data,
    this.title = 'DISTRACTION HEATMAP',
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = data.values.isEmpty ? 1 : data.values.reduce(math.max);

    // Column labels: every 3 hours
    const hourLabels = ['0', '3', '6', '9', '12', '15', '18', '21'];
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LuxuryColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LuxuryColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.thermostat, color: LuxuryColors.rubyRed, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: LuxuryTextStyles.labelLarge.copyWith(
                  color: LuxuryColors.rubyRed,
                  letterSpacing: 2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'When you get distracted most',
            style: LuxuryTextStyles.bodyMedium.copyWith(
              color: LuxuryColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),

          // Hour axis labels
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: hourLabels
                  .map((h) => SizedBox(
                        width: 24,
                        child: Text(
                          h,
                          style: TextStyle(
                            color: LuxuryColors.textTertiary,
                            fontSize: 9,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Grid
          ...List.generate(7, (dayIndex) {
            final weekday = dayIndex + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  // Day label
                  SizedBox(
                    width: 32,
                    child: Text(
                      dayLabels[dayIndex],
                      style: TextStyle(
                        color: LuxuryColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  // Hour cells
                  Expanded(
                    child: Row(
                      children: List.generate(24, (hour) {
                        final key = '$weekday-$hour';
                        final count = data[key] ?? 0;
                        final intensity =
                            maxCount > 0 ? count / maxCount : 0.0;
                        return Expanded(
                          child: Tooltip(
                            message: count == 0
                                ? 'No distractions'
                                : '$count interruption${count == 1 ? '' : 's'}',
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              height: 14,
                              margin: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: _cellColor(intensity),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 14),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less',
                style: TextStyle(
                  color: LuxuryColors.textTertiary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 6),
              ...List.generate(5, (i) {
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: _cellColor(i / 4.0),
                  ),
                );
              }),
              const SizedBox(width: 6),
              Text(
                'More',
                style: TextStyle(
                  color: LuxuryColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _cellColor(double intensity) {
    if (intensity == 0) {
      return LuxuryColors.elevatedSurface;
    }
    // Interpolate from muted amber → bright ruby red
    return Color.lerp(
      const Color(0xFF4A2020), // very dark red (low)
      LuxuryColors.rubyRed,   // bright red (high)
      intensity,
    )!;
  }
}

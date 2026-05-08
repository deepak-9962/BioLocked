import 'package:flutter/material.dart';

import '../../features/app_usage/app_usage_models.dart';
import '../theme/luxury_theme.dart';

class HourlyUsageChart extends StatelessWidget {
  final List<HourlyUsageBucket> buckets;
  const HourlyUsageChart({super.key, required this.buckets});

  @override
  Widget build(BuildContext context) {
    final maxMins = buckets.isEmpty
        ? 0
        : buckets.map((b) => b.totalMinutes).reduce((a, b) => a > b ? a : b);
    if (maxMins == 0) {
      return Text(
        'No hourly usage yet.',
        style: LuxuryTextStyles.bodyMedium.copyWith(
          color: LuxuryColors.textSecondary,
        ),
      );
    }
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final bucket in buckets)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 8 + (72 * bucket.totalMinutes / maxMins),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: LuxuryColors.platinumBlue.withValues(alpha: 0.75),
                      ),
                    ),
                    if (bucket.distractingMinutes > 0)
                      Container(
                        height: 3 + (24 * bucket.distractingMinutes / maxMins),
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: LuxuryColors.rubyRed.withValues(alpha: 0.8),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      bucket.hour % 6 == 0 ? '${bucket.hour}' : '',
                      style: LuxuryTextStyles.bodyMedium.copyWith(fontSize: 8),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

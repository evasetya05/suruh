import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common_widgets.dart';

/// Seven-day revenue bar chart.
///
/// Hand-drawn with `CustomPaint` rather than a charting package: one small
/// chart does not justify the dependency, and this keeps full control of the
/// theme colours in light and dark mode.
class RevenueSparkline extends StatelessWidget {
  const RevenueSparkline({required this.values, super.key});

  /// Oldest first; the last entry is today.
  final List<double> values;

  static const List<String> _dayLabels = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (values.isEmpty) return const SizedBox.shrink();

    final double total = values.fold<double>(0, (double s, double v) => s + v);
    final double peak = values.reduce(math.max);

    // Labels are anchored to today and walked backwards so "Sun" lands on the
    // right day rather than always at the end of the list.
    final int todayIndex = DateTime.now().weekday - 1;
    final List<String> labels = List<String>.generate(
      values.length,
      (int i) => _dayLabels[
          (todayIndex - (values.length - 1 - i) + 7 * 2) % 7],
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Last 7 days', style: theme.textTheme.titleMedium),
                    Text(
                      '${Formatters.currency(total)} in sales',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const InfoPill(
                label: 'Merchant take',
                icon: Icons.trending_up_rounded,
                color: AppColors.primary,
                filled: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 108,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(values.length, (int i) {
                final bool isToday = i == values.length - 1;
                // Guard against a flat zero week producing NaN heights.
                final double fraction = peak <= 0 ? 0 : values[i] / peak;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          values[i] == 0
                              ? '-'
                              : Formatters.currencyCompact(values[i]),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            fontWeight:
                                isToday ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: fraction),
                          duration: Duration(milliseconds: 400 + i * 60),
                          curve: Curves.easeOutCubic,
                          builder: (BuildContext context, double v, _) =>
                              Container(
                            height: math.max(4, 62 * v),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? AppColors.primary
                                  : AppColors.primary
                                      .withValues(alpha: 0.28),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xs),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          labels[i],
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight:
                                isToday ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

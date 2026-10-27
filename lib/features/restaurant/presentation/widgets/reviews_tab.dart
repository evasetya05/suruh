import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../domain/entities/review.dart';

/// Rating breakdown plus the review list.
class ReviewsTab extends StatelessWidget {
  const ReviewsTab({
    required this.reviews,
    required this.summary,
    super.key,
  });

  final List<Review> reviews;
  final RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const EmptyView(
        title: 'No reviews yet',
        message: 'Be the first to order and share what you thought.',
        icon: Icons.rate_review_outlined,
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        AppSpacing.lg,
        context.gutter,
        AppSpacing.huge * 2,
      ),
      children: <Widget>[
        ContentContainer(
          padded: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SummaryCard(summary: summary),
              const SizedBox(height: AppSpacing.xl),
              for (final Review review in reviews) ...<Widget>[
                _ReviewTile(review: review),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Column(
            children: <Widget>[
              Text(
                Formatters.rating(summary.average),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List<Widget>.generate(5, (int i) {
                  final double filled = summary.average - i;
                  return Icon(
                    filled >= 1
                        ? Icons.star_rounded
                        : (filled > 0
                            ? Icons.star_half_rounded
                            : Icons.star_outline_rounded),
                    size: 15,
                    color: AppColors.accentAmber,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${Formatters.compactCount(summary.total)} reviews',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              children: <Widget>[
                for (int star = 5; star >= 1; star--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 12,
                          child: Text(
                            '$star',
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: summary.fractionFor(star),
                              minHeight: 6,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                AppColors.accentAmber,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${summary.distribution[star] ?? 0}',
                            textAlign: TextAlign.right,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  review.userAvatarEmoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(review.userName, style: theme.textTheme.titleSmall),
                    Text(
                      Formatters.relative(review.createdAt),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              RatingBadge(rating: review.rating, compact: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(review.comment, style: theme.textTheme.bodyMedium),
          if (review.orderedItems.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: review.orderedItems
                  .map((String item) => InfoPill(label: item))
                  .toList(growable: false),
            ),
          ],
          if (review.likes > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Icon(
                  Icons.thumb_up_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  '${review.likes} found this helpful',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

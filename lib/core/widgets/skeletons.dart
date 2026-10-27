import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_spacing.dart';

/// Shimmer wrapper that picks base/highlight colours from the active theme so
/// skeletons look right in both light and dark mode.
class AppShimmer extends StatelessWidget {
  const AppShimmer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF232B35) : const Color(0xFFE9ECF1),
      highlightColor: isDark ? const Color(0xFF2E3743) : const Color(0xFFF7F9FC),
      child: child,
    );
  }
}

/// Grey block used to compose skeleton layouts.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    this.width,
    this.height = 14,
    this.radius = AppRadius.xs,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Placeholder matching the large restaurant card layout.
class RestaurantCardSkeleton extends StatelessWidget {
  const RestaurantCardSkeleton({this.width = 260, super.key});

  final double width;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SkeletonBox(height: 140, radius: AppRadius.lg, width: width),
            const SizedBox(height: AppSpacing.md),
            SkeletonBox(width: width * 0.72, height: 15),
            const SizedBox(height: AppSpacing.sm),
            SkeletonBox(width: width * 0.5, height: 12),
          ],
        ),
      ),
    );
  }
}

/// Placeholder matching a horizontal menu/dish row.
class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SkeletonBox(width: 92, height: 92, radius: AppRadius.md),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SkeletonBox(width: 160, height: 15),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: double.infinity, height: 12),
                SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: 200, height: 12),
                SizedBox(height: AppSpacing.md),
                SkeletonBox(width: 70, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontally scrolling row of restaurant skeletons.
class HorizontalSkeletonRow extends StatelessWidget {
  const HorizontalSkeletonRow({
    this.itemCount = 3,
    this.itemWidth = 260,
    this.height = 230,
    super.key,
  });

  final int itemCount;
  final double itemWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (_, __) => RestaurantCardSkeleton(width: itemWidth),
      ),
    );
  }
}

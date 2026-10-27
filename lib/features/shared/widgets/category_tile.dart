import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/food_category.dart';

/// Round service tile from the Grab super-app home grid.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    required this.category,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  final FoodCategory category;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Deterministic tint per category so the grid keeps a stable, designed look.
    final Color tint = AppColors.tintFor(category.id);

    return SizedBox(
      width: 76,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: selected
                      ? tint
                      : tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: selected
                      ? Border.all(color: tint, width: 2)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? tint : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrolling row of [CategoryTile]s.
class CategoryStrip extends StatelessWidget {
  const CategoryStrip({
    required this.categories,
    required this.onSelected,
    this.selectedId,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    super.key,
  });

  final List<FoodCategory> categories;
  final ValueChanged<FoodCategory> onSelected;
  final String? selectedId;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (BuildContext context, int i) {
          final FoodCategory category = categories[i];
          return CategoryTile(
            category: category,
            selected: category.id == selectedId,
            onTap: () => onSelected(category),
          );
        },
      ),
    );
  }
}

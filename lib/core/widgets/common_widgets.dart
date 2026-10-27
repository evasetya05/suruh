import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// `4.8 (2.4k)` rating pill used on restaurant and dish cards.
class RatingBadge extends StatelessWidget {
  const RatingBadge({
    required this.rating,
    this.reviewCount,
    this.compact = false,
    super.key,
  });

  final double rating;
  final String? reviewCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Icons.star_rounded,
          size: compact ? 14 : 16,
          color: AppColors.accentAmber,
        ),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: (compact ? theme.textTheme.labelSmall : theme.textTheme.labelLarge)
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (reviewCount != null) ...<Widget>[
          const SizedBox(width: 3),
          Text(
            '($reviewCount)',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ],
    );
  }
}

/// Small labelled pill: delivery time, distance, free-delivery flag, etc.
class InfoPill extends StatelessWidget {
  const InfoPill({
    required this.label,
    this.icon,
    this.color,
    this.filled = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color tint = color ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: filled
            ? tint.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: filled ? null : Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 13, color: tint),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: filled ? tint : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section title with an optional "See all" trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.md),
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.textTheme.titleLarge),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(actionLabel!),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Minus / count / plus stepper used in the cart, dish sheet and menu rows.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.min = 1,
    this.max = 99,
    this.compact = false,
    super.key,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final int min;
  final int max;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double size = compact ? 30 : 36;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StepButton(
            icon: quantity <= min ? Icons.delete_outline_rounded : Icons.remove_rounded,
            size: size,
            onTap: quantity > min || min == 0 ? onDecrement : null,
            tooltip: quantity <= min ? 'Remove' : 'Decrease quantity',
          ),
          SizedBox(
            width: compact ? 28 : 34,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            size: size,
            filled: true,
            onTap: quantity < max ? onIncrement : null,
            tooltip: 'Increase quantity',
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.size,
    required this.tooltip,
    this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final double size;
  final String tooltip;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled
            ? (enabled ? AppColors.primary : theme.disabledColor)
            : theme.colorScheme.surface,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            height: size,
            width: size,
            child: Icon(
              icon,
              size: size * 0.5,
              color: filled
                  ? Colors.white
                  : (enabled
                      ? theme.colorScheme.onSurface
                      : theme.disabledColor),
            ),
          ),
        ),
      ),
    );
  }
}

/// White rounded card with the app's standard border - the base surface for
/// nearly every list item and panel.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.lg,
    this.color,
    this.border = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // `shape` carries the radius; passing `borderRadius` as well trips a
    // Material assertion, so only one of the two is ever set.
    return Material(
      color: color ?? theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: border
            ? BorderSide(color: theme.colorScheme.outlineVariant)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Row of `label ......... value`, used in order summaries and receipts.
class SummaryRow extends StatelessWidget {
  const SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? style = emphasize
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Text(
              label,
              style: emphasize
                  ? style
                  : style?.copyWith(color: theme.textTheme.bodySmall?.color),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(value, style: style?.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}

/// Section divider with generous vertical rhythm.
class AppDivider extends StatelessWidget {
  const AppDivider({this.vertical = AppSpacing.lg, super.key});

  final double vertical;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: vertical),
        child: const Divider(height: 1),
      );
}

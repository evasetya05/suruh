import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, tonal, danger }

enum AppButtonSize { regular, compact }

/// Single button entry point for the whole app.
///
/// Handles the in-flight state itself (spinner + disabled) so no screen has to
/// re-implement "disable while the bloc is submitting".
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool disabled = onPressed == null || isLoading;
    final double height = size == AppButtonSize.regular ? 52 : 42;

    final Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == AppButtonVariant.primary ||
                        variant == AppButtonVariant.danger
                    ? Colors.white
                    : AppColors.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: size == AppButtonSize.regular ? 20 : 18),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );

    final ButtonStyle style = switch (variant) {
      AppButtonVariant.primary => ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: Size(expand ? double.infinity : 0, height),
        ),
      AppButtonVariant.danger => ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger,
          foregroundColor: Colors.white,
          minimumSize: Size(expand ? double.infinity : 0, height),
        ),
      AppButtonVariant.tonal => ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          foregroundColor: AppColors.primaryDark,
          minimumSize: Size(expand ? double.infinity : 0, height),
          elevation: 0,
        ),
      AppButtonVariant.secondary => OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          minimumSize: Size(expand ? double.infinity : 0, height),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
    };

    if (variant == AppButtonVariant.secondary) {
      return OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: style,
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: disabled ? null : onPressed,
      style: style,
      child: child,
    );
  }
}

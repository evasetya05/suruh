import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/link_launcher.dart';
import 'app_logo.dart';

/// Attribution linking back to the article this demo accompanies.
///
/// Shown on the sign-in screen and in the profile's about section, so anyone
/// exploring the build can find the write-up that explains it.
class ArticleCredit extends StatelessWidget {
  const ArticleCredit({this.compact = false, super.key});

  /// A single tappable line instead of the full card.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppConfig config = AppConfig.instance;

    Future<void> openArticle() => LinkLauncher.open(
          context,
          config.articleUrl,
          failureMessage: 'Could not open ${config.articleUrl}',
        );

    if (compact) {
      return TextButton.icon(
        onPressed: openArticle,
        icon: const Icon(Icons.menu_book_outlined, size: 16),
        label: Text('Read the article on ${config.publisher}'),
      );
    }

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: openArticle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              const AppLogo(size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Built for a ${config.publisher} article',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      config.articleUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

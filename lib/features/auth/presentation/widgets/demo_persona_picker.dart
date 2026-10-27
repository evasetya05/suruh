import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/user.dart';

class _Persona {
  const _Persona({
    required this.role,
    required this.emoji,
    required this.name,
    required this.blurb,
    required this.tint,
  });

  final UserRole role;
  final String emoji;
  final String name;
  final String blurb;
  final Color tint;
}

const List<_Persona> _personas = <_Persona>[
  _Persona(
    role: UserRole.customer,
    emoji: '👩🏻',
    name: 'Aisyah - Customer',
    blurb: 'Browse, order, track and review',
    tint: AppColors.primary,
  ),
  _Persona(
    role: UserRole.restaurantPartner,
    emoji: '👨🏻‍🍳',
    name: 'Wei Jian - Restaurant',
    blurb: 'Manage a menu and accept live orders',
    tint: AppColors.accentOrange,
  ),
  _Persona(
    role: UserRole.deliveryPartner,
    emoji: '🧑🏽',
    name: 'Muthu - Rider',
    blurb: 'Pick up jobs and update delivery status',
    tint: AppColors.accentBlue,
  ),
];

/// One-tap sign-in for each seeded role.
///
/// The three sides of a delivery marketplace are hard to appreciate from one
/// account, so the demo makes switching between them a single tap rather than
/// three sets of credentials to remember.
class DemoPersonaPicker extends StatelessWidget {
  const DemoPersonaPicker({
    required this.onSelected,
    this.enabled = true,
    super.key,
  });

  final ValueChanged<UserRole> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final _Persona persona in _personas) ...<Widget>[
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            onTap: enabled ? () => onSelected(persona.role) : null,
            child: Row(
              children: <Widget>[
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: persona.tint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    persona.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(persona.name, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(persona.blurb, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          'All demo accounts use the password demo1234.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

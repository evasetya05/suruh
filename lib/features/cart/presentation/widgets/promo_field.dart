import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/cart.dart';
import '../../bloc/cart_bloc.dart';

/// Promo code entry that flips to an "applied" chip once a code sticks.
class PromoField extends StatefulWidget {
  const PromoField({required this.cart, super.key});

  final Cart cart;

  @override
  State<PromoField> createState() => _PromoFieldState();
}

class _PromoFieldState extends State<PromoField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final String code = _controller.text.trim();
    if (code.isEmpty) return;
    context.read<CartBloc>().add(CartPromoApplied(code));
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (widget.cart.appliedPromo != null) {
      final String code = widget.cart.appliedPromo!.code;
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.local_offer_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('$code applied', style: theme.textTheme.titleSmall),
                  Text(
                    'You saved ${Formatters.currency(widget.cart.promoDiscount)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                _controller.clear();
                context.read<CartBloc>().add(const CartPromoRemoved());
              },
              child: const Text('Remove'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Have a promo code?', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _apply(),
                decoration: const InputDecoration(
                  hintText: 'e.g. MSDEV30',
                  isDense: true,
                  prefixIcon: Icon(Icons.confirmation_number_outlined, size: 20),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _apply,
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Try MSDEV30, NEWBITE or LUNCH20.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

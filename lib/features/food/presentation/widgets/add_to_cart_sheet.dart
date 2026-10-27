import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/food_item.dart';
import '../../../../domain/entities/restaurant.dart';
import '../../../cart/bloc/cart_bloc.dart';

/// Quantity + notes sheet shown before a dish reaches the basket.
///
/// It reads the [CartBloc] from the calling context and passes it down
/// explicitly, because a modal route is a sibling of the page in the widget
/// tree and would not otherwise inherit the provider.
class AddToCartSheet extends StatefulWidget {
  const AddToCartSheet({
    required this.item,
    required this.restaurant,
    super.key,
  });

  final FoodItem item;
  final Restaurant restaurant;

  static Future<void> show(
    BuildContext context, {
    required FoodItem item,
    required Restaurant restaurant,
  }) {
    final CartBloc cartBloc = context.read<CartBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider<CartBloc>.value(
        value: cartBloc,
        child: AddToCartSheet(item: item, restaurant: restaurant),
      ),
    );
  }

  @override
  State<AddToCartSheet> createState() => _AddToCartSheetState();
}

class _AddToCartSheetState extends State<AddToCartSheet> {
  final TextEditingController _notes = TextEditingController();
  int _quantity = 1;

  double get _lineTotal => widget.item.effectivePrice * _quantity;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _add() {
    context.read<CartBloc>().add(
          CartItemAdded(
            item: widget.item,
            restaurant: widget.restaurant,
            quantity: _quantity,
            notes: _notes.text.trim(),
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final FoodItem item = widget.item;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppImage(
                    seed: item.id,
                    emoji: item.emoji,
                    imageUrl: item.imageUrl,
                    height: 72,
                    width: 72,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(item.name, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: <Widget>[
                            Text(
                              Formatters.currency(item.effectivePrice),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: item.isOnOffer ? AppColors.danger : null,
                              ),
                            ),
                            if (item.isOnOffer) ...<Widget>[
                              const SizedBox(width: 6),
                              Text(
                                Formatters.currency(item.priceMyr),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const AppDivider(),
              Text('Special instructions', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _notes,
                maxLines: 2,
                maxLength: 140,
                decoration: const InputDecoration(
                  hintText: 'e.g. no chilli, extra sauce on the side',
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  QuantityStepper(
                    quantity: _quantity,
                    onIncrement: () => setState(() => _quantity++),
                    onDecrement: () => setState(
                      () => _quantity = _quantity > 1 ? _quantity - 1 : 1,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: AppButton(
                      label: 'Add • ${Formatters.currency(_lineTotal)}',
                      icon: Icons.shopping_bag_outlined,
                      onPressed: item.isAvailable ? _add : null,
                    ),
                  ),
                ],
              ),
              if (!item.isAvailable) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'This dish is sold out right now.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.danger),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

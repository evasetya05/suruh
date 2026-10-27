import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/cart.dart';
import '../bloc/cart_bloc.dart';
import 'widgets/promo_field.dart';

/// The basket: line items, promo code, price breakdown, checkout entry point.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CartBloc, CartState>(
      listenWhen: (CartState a, CartState b) =>
          a.errorMessage != b.errorMessage ||
          a.successMessage != b.successMessage,
      listener: (BuildContext context, CartState state) {
        final String? message = state.errorMessage ?? state.successMessage;
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor:
                  state.errorMessage != null ? AppColors.danger : null,
            ),
          );
        context.read<CartBloc>().add(const CartFeedbackCleared());
      },
      builder: (BuildContext context, CartState state) {
        final Cart cart = state.cart;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Your cart'),
            actions: <Widget>[
              if (cart.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _confirmClear(context),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
          body: cart.isEmpty
              ? EmptyView(
                  title: 'Your cart is empty',
                  message:
                      'Browse restaurants and add a dish to get started.',
                  icon: Icons.shopping_bag_outlined,
                  actionLabel: 'Find something to eat',
                  onAction: () => context.go(Routes.home),
                )
              : _CartBody(state: state),
          bottomNavigationBar:
              cart.isEmpty ? null : _CheckoutBar(state: state),
        );
      },
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final CartBloc bloc = context.read<CartBloc>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Clear your cart?'),
        content: const Text('This removes every item you have added.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Clear cart'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) bloc.add(const CartCleared());
  }
}

class _CartBody extends StatelessWidget {
  const _CartBody({required this.state});

  final CartState state;

  @override
  Widget build(BuildContext context) {
    final Cart cart = state.cart;
    final ThemeData theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        AppSpacing.lg,
        context.gutter,
        AppSpacing.huge,
      ),
      children: <Widget>[
        ContentContainer(
          padded: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _RestaurantBanner(cart: cart),
              const SizedBox(height: AppSpacing.lg),
              for (final CartItem line in cart.lines) ...<Widget>[
                _CartLine(line: line),
                const SizedBox(height: AppSpacing.md),
              ],
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add more items'),
              ),
              const AppDivider(),
              PromoField(cart: cart),
              const AppDivider(),
              Text('Order summary', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              SummaryRow(
                label: 'Subtotal (${cart.itemCount} items)',
                value: Formatters.currency(cart.subtotal),
              ),
              if (cart.itemSavings > 0)
                SummaryRow(
                  label: 'Item discounts',
                  value: '-${Formatters.currency(cart.itemSavings)}',
                  valueColor: AppColors.success,
                ),
              SummaryRow(
                label: 'Delivery fee',
                value: cart.deliveryFeeMyr == 0
                    ? 'Free'
                    : Formatters.currency(cart.deliveryFeeMyr),
                valueColor:
                    cart.deliveryFeeMyr == 0 ? AppColors.success : null,
              ),
              SummaryRow(
                label: 'Service fee',
                value: Formatters.currency(cart.serviceFee),
              ),
              if (cart.smallOrderFee > 0)
                SummaryRow(
                  label: 'Small order fee',
                  value: Formatters.currency(cart.smallOrderFee),
                  valueColor: AppColors.warning,
                ),
              if (cart.promoDiscount > 0)
                SummaryRow(
                  label: 'Promo ${cart.appliedPromo!.code}',
                  value: '-${Formatters.currency(cart.promoDiscount)}',
                  valueColor: AppColors.success,
                ),
              const AppDivider(vertical: AppSpacing.md),
              SummaryRow(
                label: 'Total',
                value: Formatters.currency(cart.total),
                emphasize: true,
              ),
              if (cart.isBelowMinimum) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                _MinimumOrderNotice(cart: cart),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RestaurantBanner extends StatelessWidget {
  const _RestaurantBanner({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: cart.restaurantId == null
          ? null
          : () => context.push(Routes.restaurantDetail(cart.restaurantId!)),
      child: Row(
        children: <Widget>[
          const Icon(Icons.storefront_rounded, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Ordering from', style: theme.textTheme.labelSmall),
                Text(
                  cart.restaurantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.line});

  final CartItem line;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Dismissible(
      key: ValueKey<String>(line.lineId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) =>
          context.read<CartBloc>().add(CartLineRemoved(line.lineId)),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppImage(
              seed: line.item.id,
              emoji: line.item.emoji,
              imageUrl: line.item.imageUrl,
              height: 64,
              width: 64,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    line.item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (line.notes.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      line.notes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: <Widget>[
                      Text(
                        Formatters.currency(line.lineTotal),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      QuantityStepper(
                        quantity: line.quantity,
                        compact: true,
                        min: 0,
                        onIncrement: () => context.read<CartBloc>().add(
                              CartQuantityChanged(
                                lineId: line.lineId,
                                quantity: line.quantity + 1,
                              ),
                            ),
                        onDecrement: () => context.read<CartBloc>().add(
                              CartQuantityChanged(
                                lineId: line.lineId,
                                quantity: line.quantity - 1,
                              ),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimumOrderNotice extends StatelessWidget {
  const _MinimumOrderNotice({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.info_outline_rounded, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Add ${Formatters.currency(cart.amountToMinimum)} more to reach the '
              '${Formatters.currency(cart.minOrderMyr)} minimum and skip the '
              'small order fee.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.state});

  final CartState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Total', style: theme.textTheme.labelSmall),
              Text(
                Formatters.currency(state.cart.total),
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: AppButton(
              label: 'Go to checkout',
              icon: Icons.arrow_forward_rounded,
              isLoading: state.isBusy,
              onPressed: () => context.push(Routes.checkout),
            ),
          ),
        ],
      ),
    );
  }
}

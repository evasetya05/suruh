import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/service_locator.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/address.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/order_usecases.dart';
import '../../../domain/usecases/user_usecases.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../bloc/checkout_bloc.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = context.read<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(
        body: ErrorView(message: 'You need to be signed in to check out.'),
      );
    }

    return BlocProvider<CheckoutBloc>(
      create: (_) => CheckoutBloc(
        placeOrder: sl<PlaceOrder>(),
        getAddresses: sl<GetAddresses>(),
      )..add(CheckoutStarted(user)),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatelessWidget {
  const _CheckoutView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckoutBloc, CheckoutState>(
      listenWhen: (CheckoutState a, CheckoutState b) =>
          a.status != b.status || a.errorMessage != b.errorMessage,
      listener: (BuildContext context, CheckoutState state) {
        if (state.placedOrder != null &&
            state.status == CheckoutStatus.placed) {
          // Replace the checkout route so back does not land on a stale cart.
          context.go(Routes.trackOrder(state.placedOrder!.id));
          return;
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.danger,
              ),
            );
        }
      },
      builder: (BuildContext context, CheckoutState state) {
        final Cart cart = context.watch<CartBloc>().state.cart;

        if (state.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Checkout')),
            body: const LoadingView(message: 'Getting your details...'),
          );
        }

        if (cart.isEmpty && state.status != CheckoutStatus.placed) {
          return Scaffold(
            appBar: AppBar(title: const Text('Checkout')),
            body: EmptyView(
              title: 'Nothing to check out',
              message: 'Your cart is empty.',
              icon: Icons.shopping_bag_outlined,
              actionLabel: 'Browse restaurants',
              onAction: () => context.go(Routes.home),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Checkout')),
          body: ListView(
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
                    _DeliveryEta(cart: cart),
                    const SizedBox(height: AppSpacing.xl),
                    _AddressSection(state: state),
                    const SizedBox(height: AppSpacing.xl),
                    _PaymentSection(state: state),
                    const SizedBox(height: AppSpacing.xl),
                    _RiderNote(state: state),
                    const SizedBox(height: AppSpacing.xl),
                    _OrderSummary(cart: cart),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _PlaceOrderBar(state: state, cart: cart),
        );
      },
    );
  }
}

class _DeliveryEta extends StatelessWidget {
  const _DeliveryEta({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      color: AppColors.primary.withValues(alpha: 0.08),
      border: false,
      child: Row(
        children: <Widget>[
          Container(
            height: 44,
            width: 44,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.two_wheeler_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Standard delivery',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  'Arrives in about 30-40 minutes from '
                  '${cart.restaurantName}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressSection extends StatelessWidget {
  const _AddressSection({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: 'Delivery address',
          actionLabel: 'Manage',
          onAction: () => context.push(Routes.addresses),
        ),
        if (state.addresses.isEmpty)
          AppCard(
            onTap: () => context.push(Routes.addresses),
            child: Row(
              children: <Widget>[
                const Icon(Icons.add_location_alt_outlined),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Add a delivery address to continue',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )
        else
          for (final Address address in state.addresses) ...<Widget>[
            _AddressOption(
              address: address,
              selected: state.selectedAddress?.id == address.id,
              onTap: () => context
                  .read<CheckoutBloc>()
                  .add(CheckoutAddressSelected(address)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _AddressOption extends StatelessWidget {
  const _AddressOption({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final Address address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      color: selected ? AppColors.primary.withValues(alpha: 0.07) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: selected
                ? AppColors.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(address.label.display, style: theme.textTheme.titleSmall),
                    if (address.isDefault) ...<Widget>[
                      const SizedBox(width: AppSpacing.sm),
                      const InfoPill(
                        label: 'Default',
                        color: AppColors.primary,
                        filled: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(address.formatted, style: theme.textTheme.bodySmall),
                if (address.notes != null && address.notes!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    'Note: ${address.notes}',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(title: 'Payment method'),
        for (final PaymentMethod method in PaymentMethod.values) ...<Widget>[
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: state.paymentMethod == method
                ? AppColors.primary.withValues(alpha: 0.07)
                : null,
            onTap: () => context
                .read<CheckoutBloc>()
                .add(CheckoutPaymentSelected(method)),
            child: Row(
              children: <Widget>[
                Icon(
                  state.paymentMethod == method
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: state.paymentMethod == method
                      ? AppColors.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(method.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(method.label, style: theme.textTheme.titleSmall),
                ),
                if (method == PaymentMethod.card)
                  Text(
                    Formatters.maskedCard('4242'),
                    style: theme.textTheme.labelSmall,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Payment is simulated in this demo - no card is charged.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _RiderNote extends StatelessWidget {
  const _RiderNote({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(title: 'Note for the rider'),
        TextField(
          maxLines: 2,
          maxLength: 140,
          onChanged: (String value) =>
              context.read<CheckoutBloc>().add(CheckoutNoteChanged(value)),
          decoration: const InputDecoration(
            hintText: 'e.g. Call when you arrive, gate code 1234',
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(title: 'Order summary'),
        AppCard(
          child: Column(
            children: <Widget>[
              for (final CartItem line in cart.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${line.quantity}x',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              line.item.name,
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (line.notes.isNotEmpty)
                              Text(
                                line.notes,
                                style: theme.textTheme.labelSmall,
                              ),
                          ],
                        ),
                      ),
                      Text(
                        Formatters.currency(line.lineTotal),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              const AppDivider(vertical: AppSpacing.md),
              SummaryRow(
                label: 'Subtotal',
                value: Formatters.currency(cart.subtotal),
              ),
              SummaryRow(
                label: 'Delivery fee',
                value: cart.deliveryFeeMyr == 0
                    ? 'Free'
                    : Formatters.currency(cart.deliveryFeeMyr),
              ),
              SummaryRow(
                label: 'Service fee',
                value: Formatters.currency(cart.serviceFee),
              ),
              if (cart.smallOrderFee > 0)
                SummaryRow(
                  label: 'Small order fee',
                  value: Formatters.currency(cart.smallOrderFee),
                ),
              if (cart.promoDiscount > 0)
                SummaryRow(
                  label: 'Promo ${cart.appliedPromo!.code}',
                  value: '-${Formatters.currency(cart.promoDiscount)}',
                  valueColor: AppColors.success,
                ),
              const AppDivider(vertical: AppSpacing.md),
              SummaryRow(
                label: 'Total to pay',
                value: Formatters.currency(cart.total),
                emphasize: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaceOrderBar extends StatelessWidget {
  const _PlaceOrderBar({required this.state, required this.cart});

  final CheckoutState state;
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: AppButton(
        label: state.isPlacing
            ? 'Placing your order...'
            : 'Place order • ${Formatters.currency(cart.total)}',
        icon: Icons.check_circle_outline_rounded,
        isLoading: state.isPlacing,
        onPressed: state.canPlaceOrder && cart.isNotEmpty
            ? () => context.read<CheckoutBloc>().add(CheckoutSubmitted(cart))
            : null,
      ),
    );
  }
}

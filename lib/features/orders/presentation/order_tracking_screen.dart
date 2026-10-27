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
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/usecases/order_usecases.dart';
import '../bloc/order_tracking_cubit.dart';
import 'widgets/rate_order_sheet.dart';
import 'widgets/tracking_timeline.dart';

/// Live order tracking with an animated status timeline.
class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderTrackingCubit>(
      create: (_) => OrderTrackingCubit(
        getOrderById: sl<GetOrderById>(),
        watchOrder: sl<WatchOrder>(),
        cancelOrder: sl<CancelOrder>(),
      )..track(orderId),
      child: _TrackingView(orderId: orderId),
    );
  }
}

class _TrackingView extends StatelessWidget {
  const _TrackingView({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
      builder: (BuildContext context, OrderTrackingState state) {
        if (state.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Tracking your order')),
            body: const LoadingView(message: 'Finding your order...'),
          );
        }

        if (state.order == null) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorView(
              message: state.errorMessage ?? 'We could not find that order.',
              onRetry: () => context.read<OrderTrackingCubit>().track(orderId),
            ),
          );
        }

        final Order order = state.order!;

        return Scaffold(
          appBar: AppBar(
            title: Text(Formatters.orderNumber(order.id)),
            actions: <Widget>[
              IconButton(
                tooltip: 'Back to orders',
                onPressed: () => context.go(Routes.orders),
                icon: const Icon(Icons.receipt_long_outlined),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
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
                    _StatusHero(order: order),
                    const SizedBox(height: AppSpacing.xl),
                    TrackingTimeline(order: order),
                    if (order.rider != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xl),
                      _RiderCard(rider: order.rider!),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    _DeliveryCard(order: order),
                    const SizedBox(height: AppSpacing.xl),
                    _ReceiptCard(order: order),
                    const SizedBox(height: AppSpacing.xl),
                    _Actions(state: state, order: order),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Big status headline with the live ETA.
class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool cancelled = order.status == OrderStatus.cancelled;
    final bool delivered = order.status == OrderStatus.delivered;

    return AppCard(
      color: cancelled
          ? AppColors.danger.withValues(alpha: 0.08)
          : AppColors.primary.withValues(alpha: 0.08),
      border: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(order.status.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(order.status.label, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      order.status.description,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!cancelled) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: order.trackingProgress),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double value, _) =>
                    LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                const Icon(Icons.schedule_rounded, size: 16),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    delivered
                        ? 'Delivered at ${Formatters.time(order.deliveredAt ?? order.placedAt)}'
                        : 'Arriving around ${Formatters.time(order.estimatedArrival)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RiderCard extends StatelessWidget {
  const _RiderCard({required this.rider});

  final DeliveryRider rider;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      child: Row(
        children: <Widget>[
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              rider.avatarEmoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(rider.name, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${rider.vehicle} • ${rider.plateNumber}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                RatingBadge(rating: rider.rating, compact: true),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Call rider',
            onPressed: () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text('Calling ${rider.name} (demo action)')),
              ),
            icon: const Icon(Icons.phone_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Delivering to', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      order.deliveryAddress.label.display,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.deliveryAddress.formatted,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (order.riderNote != null && order.riderNote!.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.sticky_note_2_outlined, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      order.riderNote!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text('Receipt', style: theme.textTheme.titleMedium),
              ),
              InfoPill(
                label: order.paymentMethod.label,
                icon: Icons.payments_outlined,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final CartItem line in order.lines)
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
                    child: Text(
                      line.item.name,
                      style: theme.textTheme.bodyMedium,
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
            value: Formatters.currency(order.subtotal),
          ),
          SummaryRow(
            label: 'Delivery fee',
            value: order.deliveryFee == 0
                ? 'Free'
                : Formatters.currency(order.deliveryFee),
          ),
          SummaryRow(
            label: 'Service fee',
            value: Formatters.currency(order.serviceFee),
          ),
          if (order.discount > 0)
            SummaryRow(
              label: 'Discount',
              value: '-${Formatters.currency(order.discount)}',
              valueColor: AppColors.success,
            ),
          const AppDivider(vertical: AppSpacing.md),
          SummaryRow(
            label: 'Total paid',
            value: Formatters.currency(order.total),
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.state, required this.order});

  final OrderTrackingState state;
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (state.canCancel)
          AppButton(
            label: 'Cancel order',
            variant: AppButtonVariant.secondary,
            isLoading: state.isCancelling,
            onPressed: () => _confirmCancel(context),
          ),
        if (order.status == OrderStatus.delivered && !order.isRated) ...<Widget>[
          AppButton(
            label: 'Rate your order',
            icon: Icons.star_outline_rounded,
            onPressed: () => RateOrderSheet.show(context, order: order),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (!order.isActive)
          AppButton(
            label: 'Order again',
            variant: AppButtonVariant.tonal,
            icon: Icons.replay_rounded,
            onPressed: () =>
                context.push(Routes.restaurantDetail(order.restaurantId)),
          ),
      ],
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final OrderTrackingCubit cubit = context.read<OrderTrackingCubit>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
          'The restaurant has not started cooking yet, so you can still cancel '
          'free of charge.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.cancel(order.id);
  }
}

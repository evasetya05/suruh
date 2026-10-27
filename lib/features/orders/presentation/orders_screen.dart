import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/service_locator.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/order_usecases.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/orders_cubit.dart';

/// Order history split into "Active" and "Past" tabs.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(
        body: EmptyView(
          title: 'Sign in to see your orders',
          icon: Icons.receipt_long_outlined,
        ),
      );
    }

    return BlocProvider<OrdersCubit>(
      create: (_) =>
          OrdersCubit(getOrderHistory: sl<GetOrderHistory>())..load(user.id),
      child: _OrdersView(userId: user.id),
    );
  }
}

class _OrdersView extends StatelessWidget {
  const _OrdersView({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Your orders'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Active'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: BlocBuilder<OrdersCubit, OrdersState>(
          builder: (BuildContext context, OrdersState state) {
            if (state.isLoading) {
              return ListView.separated(
                padding: EdgeInsets.all(context.gutter),
                itemCount: 4,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.xl),
                itemBuilder: (_, __) => const ListTileSkeleton(),
              );
            }

            if (state.status == OrdersStatus.failure) {
              return ErrorView(
                message: state.errorMessage ?? 'Could not load your orders.',
                onRetry: () => context.read<OrdersCubit>().load(userId),
              );
            }

            return TabBarView(
              children: <Widget>[
                _OrderList(
                  orders: state.active,
                  userId: userId,
                  emptyTitle: 'No orders in progress',
                  emptyMessage:
                      'When you place an order it will show up here with live '
                      'tracking.',
                ),
                _OrderList(
                  orders: state.past,
                  userId: userId,
                  emptyTitle: 'No past orders yet',
                  emptyMessage: 'Your completed orders will be listed here.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.userId,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final List<Order> orders;
  final String userId;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return EmptyView(
        title: emptyTitle,
        message: emptyMessage,
        icon: Icons.receipt_long_outlined,
        actionLabel: 'Browse restaurants',
        onAction: () => context.go(Routes.home),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<OrdersCubit>().load(userId, silent: true),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          context.gutter,
          AppSpacing.lg,
          context.gutter,
          AppSpacing.huge,
        ),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (BuildContext context, int i) =>
            ContentContainer(padded: false, child: OrderCard(order: orders[i])),
      ),
    );
  }
}

/// Order row shared by the customer history and the rider's completed list.
class OrderCard extends StatelessWidget {
  const OrderCard({required this.order, this.onTap, super.key});

  final Order order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      onTap: onTap ?? () => context.push(Routes.trackOrder(order.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppImage(
                seed: order.restaurantId,
                emoji: order.restaurantEmoji,
                height: 48,
                width: 48,
                emojiScale: 0.5,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      order.restaurantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      Formatters.dateTime(order.placedAt),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              OrderStatusPill(status: order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            order.itemSummary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Text(
                Formatters.currency(order.total),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '• ${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              if (order.isActive)
                Row(
                  children: <Widget>[
                    Text(
                      'Track',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: AppColors.primary),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                )
              else if (!order.isRated &&
                  order.status == OrderStatus.delivered)
                const InfoPill(
                  label: 'Rate this order',
                  icon: Icons.star_outline_rounded,
                  color: AppColors.accentAmber,
                  filled: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Coloured status chip, shared by every screen that shows an order.
class OrderStatusPill extends StatelessWidget {
  const OrderStatusPill({required this.status, super.key});

  final OrderStatus status;

  Color get _color => switch (status) {
        OrderStatus.placed => AppColors.info,
        OrderStatus.confirmed => AppColors.info,
        OrderStatus.preparing => AppColors.accentOrange,
        OrderStatus.readyForPickup => AppColors.accentPurple,
        OrderStatus.outForDelivery => AppColors.primary,
        OrderStatus.delivered => AppColors.success,
        OrderStatus.cancelled => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

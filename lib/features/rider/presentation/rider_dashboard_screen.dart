import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/cubit/theme_cubit.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/order_usecases.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../orders/presentation/orders_screen.dart';
import '../bloc/rider_cubit.dart';

/// Delivery partner home: earnings, available jobs, active deliveries.
class RiderDashboardScreen extends StatelessWidget {
  const RiderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RiderCubit>(
      create: (_) => RiderCubit(
        watchOrders: sl<WatchRiderOrders>(),
        updateStatus: sl<UpdateOrderStatus>(),
      )..start(),
      child: const _RiderView(),
    );
  }
}

class _RiderView extends StatelessWidget {
  const _RiderView();

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<AuthBloc>().state.user;

    return BlocConsumer<RiderCubit, RiderState>(
      listenWhen: (RiderState a, RiderState b) =>
          a.successMessage != b.successMessage ||
          a.errorMessage != b.errorMessage,
      listener: (BuildContext context, RiderState state) {
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
        context.read<RiderCubit>().clearMessages();
      },
      builder: (BuildContext context, RiderState state) {
        if (state.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Rider dashboard')),
            body: const LoadingView(message: 'Finding jobs near you...'),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Rider dashboard'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Switch theme',
                onPressed: () => context.read<ThemeCubit>().cycle(),
                icon: const Icon(Icons.brightness_6_rounded),
              ),
              IconButton(
                tooltip: 'Sign out',
                onPressed: () => context
                    .read<AuthBloc>()
                    .add(const AuthSignOutRequested()),
                icon: const Icon(Icons.logout_rounded),
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
                    _RiderHeader(user: user, state: state),
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeader(
                      title: 'Active deliveries',
                      subtitle: state.active.isEmpty
                          ? 'Nothing on your bike right now'
                          : '${state.active.length} in progress',
                    ),
                    if (state.active.isEmpty)
                      const _IdleCard(
                        emoji: '🛵',
                        title: 'No active delivery',
                        message:
                            'Accept a job below and it will appear here with '
                            'the pickup and drop-off details.',
                      )
                    else
                      for (final Order order in state.active) ...<Widget>[
                        _JobCard(
                          order: order,
                          isBusy: state.busyOrderId == order.id,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(
                      title: 'Available jobs',
                      subtitle: state.isOnline
                          ? '${state.available.length} waiting for a rider'
                          : 'You are offline - go online to see jobs',
                    ),
                    if (!state.isOnline)
                      const _IdleCard(
                        emoji: '😴',
                        title: 'You are offline',
                        message:
                            'Flip the switch above to start receiving jobs.',
                      )
                    else if (state.available.isEmpty)
                      const _IdleCard(
                        emoji: '⏳',
                        title: 'No jobs right now',
                        message:
                            'Jobs appear as soon as a restaurant marks an '
                            'order ready for pickup.',
                      )
                    else
                      for (final Order order in state.available) ...<Widget>[
                        _JobCard(
                          order: order,
                          isBusy: state.busyOrderId == order.id,
                          isAvailable: true,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    if (state.completed.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.lg),
                      SectionHeader(
                        title: 'Completed today',
                        subtitle: '${state.completed.length} finished',
                      ),
                      for (final Order order in state.completed) ...<Widget>[
                        OrderCard(order: order, onTap: () {}),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
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

class _RiderHeader extends StatelessWidget {
  const _RiderHeader({required this.state, this.user});

  final User? user;
  final RiderState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: state.isOnline
              ? <Color>[AppColors.accentBlue, const Color(0xFF0A55B0)]
              : <Color>[const Color(0xFF6B7280), const Color(0xFF4B5563)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  user?.avatarEmoji ?? '🛵',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      user?.name ?? 'Rider',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      state.isOnline ? 'Online • accepting jobs' : 'Offline',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: state.isOnline,
                onChanged: (bool value) =>
                    context.read<RiderCubit>().setOnline(isOnline: value),
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.white.withValues(alpha: 0.42),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: <Widget>[
              _RiderStat(
                value: Formatters.currency(state.todayEarnings),
                label: "Today's earnings",
              ),
              _RiderStat(
                value: '${state.deliveriesToday}',
                label: 'Deliveries',
              ),
              _RiderStat(
                value: '${state.active.length}',
                label: 'In progress',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiderStat extends StatelessWidget {
  const _RiderStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// A delivery job: pickup, drop-off, and the single next action.
class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.order,
    this.isBusy = false,
    this.isAvailable = false,
  });

  final Order order;
  final bool isBusy;
  final bool isAvailable;

  String get _actionLabel => switch (order.status) {
        OrderStatus.readyForPickup =>
          isAvailable ? 'Accept job' : 'Picked up - start delivery',
        OrderStatus.outForDelivery => 'Mark as delivered',
        _ => 'Update status',
      };

  /// Riders only ever move an order forward one step.
  OrderStatus? get _nextStatus => switch (order.status) {
        OrderStatus.readyForPickup => OrderStatus.outForDelivery,
        OrderStatus.outForDelivery => OrderStatus.delivered,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final OrderStatus? next = _nextStatus;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Wrap rather than Row: the id plus two pills do not fit on one line
          // on a narrow phone, and this lets them flow instead of clipping.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                Formatters.orderNumber(order.id),
                style: theme.textTheme.titleSmall,
              ),
              InfoPill(
                label: Formatters.currency(order.deliveryFee + 4),
                icon: Icons.payments_rounded,
                color: AppColors.primary,
                filled: true,
              ),
              OrderStatusPill(status: order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Leg(
            icon: Icons.storefront_rounded,
            tint: AppColors.accentOrange,
            title: 'Pick up',
            name: order.restaurantName,
            detail: '${order.itemCount} items • ${order.itemSummary}',
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15, top: 2, bottom: 2),
            child: Container(
              width: 2,
              height: 18,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          _Leg(
            icon: Icons.location_on_rounded,
            tint: AppColors.primary,
            title: 'Drop off',
            name: order.customerName.isEmpty
                ? 'Customer'
                : order.customerName,
            detail: order.deliveryAddress.formatted,
          ),
          if (order.riderNote != null && order.riderNote!.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.info_outline_rounded, size: 15),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.riderNote!,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const AppDivider(vertical: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          'Calling ${order.customerName} (demo action)',
                        ),
                      ),
                    ),
                  icon: const Icon(Icons.phone_rounded, size: 16),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: next == null || isBusy
                      ? null
                      : () =>
                          context.read<RiderCubit>().advance(order.id, next),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    backgroundColor: AppColors.primary,
                  ),
                  child: isBusy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_actionLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Leg extends StatelessWidget {
  const _Leg({
    required this.icon,
    required this.tint,
    required this.title,
    required this.name,
    required this.detail,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 17, color: tint),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: theme.textTheme.labelSmall),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IdleCard extends StatelessWidget {
  const _IdleCard({
    required this.emoji,
    required this.title,
    required this.message,
  });

  final String emoji;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: <Widget>[
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(message, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

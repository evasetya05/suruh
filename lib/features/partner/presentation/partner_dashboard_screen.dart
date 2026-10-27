import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/cubit/theme_cubit.dart';
import '../../../app/di/service_locator.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/restaurant.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/partner_repository.dart';
import '../../../domain/usecases/order_usecases.dart';
import '../../../domain/usecases/partner_usecases.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/partner_bloc.dart';
import 'widgets/partner_order_card.dart';
import 'widgets/revenue_sparkline.dart';

/// Builds the partner bloc with all eight use cases wired.
///
/// Shared by the dashboard, menu and orders screens so each can be opened
/// directly by URL on web without depending on a parent provider.
PartnerBloc buildPartnerBloc() => PartnerBloc(
      getDashboard: sl<GetPartnerDashboard>(),
      watchOrders: sl<WatchRestaurantOrders>(),
      updateOrderStatus: sl<UpdateOrderStatus>(),
      createMenuItem: sl<CreateMenuItem>(),
      updateMenuItem: sl<UpdateMenuItem>(),
      deleteMenuItem: sl<DeleteMenuItem>(),
      setAvailability: sl<SetItemAvailability>(),
      setRestaurantOpen: sl<SetRestaurantOpen>(),
    );

/// Restaurant partner home: today's numbers, the incoming queue, quick actions.
class PartnerDashboardScreen extends StatelessWidget {
  const PartnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = context.read<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(body: ErrorView(message: 'Not signed in.'));
    }

    return BlocProvider<PartnerBloc>(
      create: (_) => buildPartnerBloc()..add(PartnerStarted(user.id)),
      child: _DashboardView(ownerId: user.id),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.ownerId});

  final String ownerId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PartnerBloc, PartnerState>(
      listenWhen: (PartnerState a, PartnerState b) =>
          a.successMessage != b.successMessage ||
          a.errorMessage != b.errorMessage,
      listener: (BuildContext context, PartnerState state) {
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
        context.read<PartnerBloc>().add(const PartnerMessageCleared());
      },
      builder: (BuildContext context, PartnerState state) {
        if (state.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Merchant dashboard')),
            body: const LoadingView(message: 'Opening your storefront...'),
          );
        }

        if (state.status == PartnerStatus.failure || state.restaurant == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Merchant dashboard')),
            body: ErrorView(
              message: state.errorMessage ??
                  'No restaurant is linked to this account.',
              onRetry: () =>
                  context.read<PartnerBloc>().add(PartnerStarted(ownerId)),
            ),
          );
        }

        final Restaurant restaurant = state.restaurant!;
        final PartnerOrderQueues queues = state.queues;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Merchant dashboard'),
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
                    _StoreCard(restaurant: restaurant),
                    const SizedBox(height: AppSpacing.xl),
                    _StatsGrid(state: state),
                    if (state.stats != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xl),
                      RevenueSparkline(values: state.stats!.revenueByDay),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    _QuickActions(pendingCount: queues.incoming.length),
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeader(
                      title: 'Incoming orders',
                      subtitle: queues.incoming.isEmpty
                          ? 'Nothing waiting to be accepted'
                          : '${queues.incoming.length} waiting for you',
                      actionLabel: 'All orders',
                      onAction: () => context.push(Routes.partnerOrders),
                    ),
                    if (queues.incoming.isEmpty)
                      const _CalmState()
                    else
                      for (final Order order in queues.incoming) ...<Widget>[
                        PartnerOrderCard(
                          order: order,
                          isBusy: state.busyOrderId == order.id,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    if (queues.inKitchen.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.lg),
                      SectionHeader(
                        title: 'In the kitchen',
                        subtitle: '${queues.inKitchen.length} in progress',
                      ),
                      for (final Order order in queues.inKitchen) ...<Widget>[
                        PartnerOrderCard(
                          order: order,
                          isBusy: state.busyOrderId == order.id,
                        ),
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

/// Storefront identity plus the open/closed switch.
class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: restaurant.isOpen
              ? <Color>[AppColors.primary, AppColors.primaryDark]
              : <Color>[const Color(0xFF6B7280), const Color(0xFF4B5563)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Text(
              restaurant.emoji,
              style: const TextStyle(fontSize: 26),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  restaurant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  restaurant.isOpen
                      ? 'Accepting orders • ${restaurant.openingTime}-${restaurant.closingTime}'
                      : 'Closed - customers cannot order',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: restaurant.isOpen,
            onChanged: (bool value) =>
                context.read<PartnerBloc>().add(PartnerStoreToggled(value)),
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white.withValues(alpha: 0.42),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.state});

  final PartnerState state;

  @override
  Widget build(BuildContext context) {
    final PartnerStats? stats = state.stats;

    final List<Widget> tiles = <Widget>[
      _StatTile(
        label: "Today's revenue",
        value: Formatters.currency(state.liveTodayRevenue),
        icon: Icons.payments_rounded,
        tint: AppColors.primary,
      ),
      _StatTile(
        label: "Today's orders",
        value: '${state.liveTodayOrders}',
        icon: Icons.receipt_long_rounded,
        tint: AppColors.accentBlue,
      ),
      _StatTile(
        label: 'Awaiting action',
        value: '${state.queues.incoming.length}',
        icon: Icons.notifications_active_rounded,
        tint: AppColors.accentOrange,
      ),
      _StatTile(
        label: 'Rating',
        value: stats == null ? '-' : Formatters.rating(stats.averageRating),
        icon: Icons.star_rounded,
        tint: AppColors.accentAmber,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: context.isMobile ? 2 : 4,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      // Tiles stack icon, value and label vertically; too wide an aspect ratio
      // clips the label on a narrow phone.
      childAspectRatio: context.isMobile ? 1.32 : 1.4,
      children: tiles,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.pendingCount});

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _ActionTile(
            icon: Icons.restaurant_menu_rounded,
            label: 'Manage menu',
            onTap: () => context.push(Routes.partnerMenu),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionTile(
            icon: Icons.list_alt_rounded,
            label: 'All orders',
            badge: pendingCount,
            onTap: () => context.push(Routes.partnerOrders),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionTile(
            icon: Icons.add_circle_outline_rounded,
            label: 'Add dish',
            onTap: () => context.push(Routes.partnerMenuEditor),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        children: <Widget>[
          Badge(
            isLabelVisible: badge > 0,
            label: Text('$badge'),
            child: Icon(icon, size: 24, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: theme.textTheme.labelSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CalmState extends StatelessWidget {
  const _CalmState();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: <Widget>[
          const Text('☕', style: TextStyle(fontSize: 30)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('All caught up', style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'New orders appear here the moment a customer places one.',
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

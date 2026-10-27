import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/partner_usecases.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/partner_bloc.dart';
import 'partner_dashboard_screen.dart';
import 'widgets/partner_order_card.dart';

/// Full order book, split into Incoming / In kitchen / Completed.
class PartnerOrdersScreen extends StatelessWidget {
  const PartnerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = context.read<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(body: ErrorView(message: 'Not signed in.'));
    }

    return BlocProvider<PartnerBloc>(
      create: (_) => buildPartnerBloc()..add(PartnerStarted(user.id)),
      child: const _PartnerOrdersView(),
    );
  }
}

class _PartnerOrdersView extends StatelessWidget {
  const _PartnerOrdersView();

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
            appBar: AppBar(title: const Text('Orders')),
            body: const LoadingView(),
          );
        }

        final PartnerOrderQueues queues = state.queues;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Orders'),
              bottom: TabBar(
                isScrollable: context.isMobile,
                tabAlignment:
                    context.isMobile ? TabAlignment.start : TabAlignment.fill,
                tabs: <Widget>[
                  Tab(text: 'Incoming (${queues.incoming.length})'),
                  Tab(text: 'In kitchen (${queues.inKitchen.length})'),
                  Tab(text: 'Completed (${queues.completed.length})'),
                ],
              ),
            ),
            body: TabBarView(
              children: <Widget>[
                _Queue(
                  orders: queues.incoming,
                  busyOrderId: state.busyOrderId,
                  emptyTitle: 'No new orders',
                  emptyMessage:
                      'Orders land here the moment a customer checks out.',
                ),
                _Queue(
                  orders: queues.inKitchen,
                  busyOrderId: state.busyOrderId,
                  emptyTitle: 'Kitchen is clear',
                  emptyMessage: 'Accepted orders show up here.',
                ),
                _Queue(
                  orders: queues.completed,
                  busyOrderId: state.busyOrderId,
                  emptyTitle: 'Nothing completed yet',
                  emptyMessage:
                      'Delivered and cancelled orders are archived here.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Queue extends StatelessWidget {
  const _Queue({
    required this.orders,
    required this.emptyTitle,
    required this.emptyMessage,
    this.busyOrderId,
  });

  final List<Order> orders;
  final String? busyOrderId;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return EmptyView(
        title: emptyTitle,
        message: emptyMessage,
        icon: Icons.inbox_outlined,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        AppSpacing.lg,
        context.gutter,
        AppSpacing.huge,
      ),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (BuildContext context, int i) => ContentContainer(
        padded: false,
        child: PartnerOrderCard(
          order: orders[i],
          isBusy: busyOrderId == orders[i].id,
        ),
      ),
    );
  }
}

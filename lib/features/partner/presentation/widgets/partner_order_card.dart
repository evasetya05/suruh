import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/cart.dart';
import '../../../../domain/entities/order.dart';
import '../../../orders/presentation/orders_screen.dart';
import '../../bloc/partner_bloc.dart';

/// Order ticket for the merchant.
///
/// The primary button always names the *next* state, so the kitchen never has
/// to work out which of six statuses to pick from a menu.
class PartnerOrderCard extends StatelessWidget {
  const PartnerOrderCard({
    required this.order,
    this.isBusy = false,
    super.key,
  });

  final Order order;
  final bool isBusy;

  /// Label for advancing to [OrderStatus.next], phrased as an action.
  String? get _advanceLabel => switch (order.status) {
        OrderStatus.placed => 'Accept order',
        OrderStatus.confirmed => 'Start cooking',
        OrderStatus.preparing => 'Mark ready for pickup',
        OrderStatus.readyForPickup => 'Hand to rider',
        OrderStatus.outForDelivery => 'Mark delivered',
        OrderStatus.delivered || OrderStatus.cancelled => null,
      };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final OrderStatus? next = order.status.next;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      Formatters.orderNumber(order.id),
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      '${order.customerName} • '
                      '${Formatters.relative(order.placedAt)}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              OrderStatusPill(status: order.status),
            ],
          ),
          const AppDivider(vertical: AppSpacing.md),
          for (final CartItem line in order.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 26,
                    child: Text(
                      '${line.quantity}x',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: AppColors.primary),
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
                            '“${line.notes}”',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.accentOrange,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.currency(line.lineTotal),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          const AppDivider(vertical: AppSpacing.md),
          Row(
            children: <Widget>[
              const Icon(Icons.location_on_outlined, size: 15),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  order.deliveryAddress.shortForm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall,
                ),
              ),
              Text(
                Formatters.currency(order.total),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (next != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                if (order.status == OrderStatus.placed) ...<Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isBusy
                          ? null
                          : () => context.read<PartnerBloc>().add(
                                PartnerOrderAdvanced(
                                  orderId: order.id,
                                  status: OrderStatus.cancelled,
                                ),
                              ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: isBusy
                        ? null
                        : () => context.read<PartnerBloc>().add(
                              PartnerOrderAdvanced(
                                orderId: order.id,
                                status: next,
                              ),
                            ),
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
                        : Text(_advanceLabel ?? 'Advance'),
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

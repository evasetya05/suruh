import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/order.dart';

/// Vertical status timeline: confirmed -> preparing -> out for delivery ->
/// delivered.
///
/// Stage timestamps come from the order's own event log rather than being
/// recomputed here, so what the customer sees matches the audit trail exactly.
class TrackingTimeline extends StatelessWidget {
  const TrackingTimeline({required this.order, super.key});

  final Order order;

  /// The most recent recorded time for [status], or null if it has not happened.
  DateTime? _timeFor(OrderStatus status) {
    for (final OrderEvent event in order.timeline.reversed) {
      if (event.status == status) return event.at;
    }
    return null;
  }

  /// Index of the stage the order is currently sitting in.
  int get _activeStage => switch (order.status) {
        OrderStatus.placed || OrderStatus.confirmed => 0,
        OrderStatus.preparing || OrderStatus.readyForPickup => 1,
        OrderStatus.outForDelivery => 2,
        OrderStatus.delivered => 3,
        OrderStatus.cancelled => -1,
      };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (order.status == OrderStatus.cancelled) {
      return AppCard(
        child: Row(
          children: <Widget>[
            const Icon(Icons.cancel_outlined, color: AppColors.danger),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Order cancelled', style: theme.textTheme.titleSmall),
                  Text(
                    order.timeline.last.note ?? 'This order was cancelled.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    const List<OrderStatus> stages = OrderStatus.trackingStages;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Progress', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          for (int i = 0; i < stages.length; i++)
            _Stage(
              status: stages[i],
              at: _timeFor(stages[i]),
              isDone: i < _activeStage,
              isCurrent: i == _activeStage,
              isLast: i == stages.length - 1,
            ),
        ],
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({
    required this.status,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    this.at,
  });

  final OrderStatus status;
  final DateTime? at;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool reached = isDone || isCurrent;
    final Color color =
        reached ? AppColors.primary : theme.colorScheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              _Marker(isDone: isDone, isCurrent: isCurrent, color: color),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: isDone
                        ? AppColors.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          status.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: reached
                                ? null
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight:
                                isCurrent ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (at != null)
                        Text(
                          Formatters.time(at!),
                          style: theme.textTheme.labelSmall,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status.description,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The dot on the timeline. The current stage pulses so it is obvious where the
/// order actually is at a glance.
class _Marker extends StatefulWidget {
  const _Marker({
    required this.isDone,
    required this.isCurrent,
    required this.color,
  });

  final bool isDone;
  final bool isCurrent;
  final Color color;

  @override
  State<_Marker> createState() => _MarkerState();
}

class _MarkerState extends State<_Marker>
    with SingleTickerProviderStateMixin {
  // Created eagerly in initState, not lazily. A `late final` initialiser would
  // not run for markers that never pulse, and `dispose` touching it would then
  // construct an AnimationController - and a Ticker - while the element is
  // already deactivated.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isCurrent) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Marker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isCurrent && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget dot = Container(
      height: 24,
      width: 24,
      decoration: BoxDecoration(
        color: widget.isDone || widget.isCurrent
            ? AppColors.primary
            : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: widget.color, width: 2),
      ),
      child: widget.isDone
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );

    if (!widget.isCurrent) return dot;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) => Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            height: 24 + 14 * _controller.value,
            width: 24 + 14 * _controller.value,
            decoration: BoxDecoration(
              color: AppColors.primary
                  .withValues(alpha: 0.25 * (1 - _controller.value)),
              shape: BoxShape.circle,
            ),
          ),
          child!,
        ],
      ),
      child: dot,
    );
  }
}

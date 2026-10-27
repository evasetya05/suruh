import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/result.dart';
import '../../../../domain/entities/cart.dart';
import '../../../../domain/entities/order.dart';
import '../../../../domain/entities/review.dart';
import '../../../../domain/usecases/review_usecases.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../bloc/order_tracking_cubit.dart';

/// Star rating + comment sheet shown after delivery.
class RateOrderSheet extends StatefulWidget {
  const RateOrderSheet({required this.order, super.key});

  final Order order;

  static Future<void> show(BuildContext context, {required Order order}) {
    final AuthBloc auth = context.read<AuthBloc>();
    final OrderTrackingCubit tracking = context.read<OrderTrackingCubit>();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<AuthBloc>.value(value: auth),
          BlocProvider<OrderTrackingCubit>.value(value: tracking),
        ],
        child: RateOrderSheet(order: order),
      ),
    );
  }

  @override
  State<RateOrderSheet> createState() => _RateOrderSheetState();
}

class _RateOrderSheetState extends State<RateOrderSheet> {
  final TextEditingController _comment = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  static const List<String> _prompts = <String>[
    'What went wrong?',
    'What went wrong?',
    'How could this be better?',
    'What did you enjoy?',
    'What made it great?',
  ];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String? userId = context.read<AuthBloc>().state.user?.id;
    final String userName =
        context.read<AuthBloc>().state.user?.name ?? 'Guest';
    if (userId == null) return;

    setState(() => _submitting = true);

    final Result<Review> result = await sl<SubmitReview>()(
      SubmitReviewParams(
        restaurantId: widget.order.restaurantId,
        userId: userId,
        userName: userName,
        rating: _rating.toDouble(),
        comment: _comment.text,
        orderId: widget.order.id,
        orderedItems: widget.order.lines
            .map((CartItem l) => l.item.name)
            .toList(growable: false),
      ),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    result.fold(
      (Failure failure) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.danger,
          ),
        ),
      (Review _) {
        // Re-read the order so the "Rate your order" button disappears.
        context.read<OrderTrackingCubit>().track(widget.order.id);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Thanks for the feedback!')),
          );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Padding(
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
              Text(
                'How was ${widget.order.restaurantName}?',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.order.itemSummary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: List<Widget>.generate(5, (int i) {
                    final int star = i + 1;
                    return IconButton(
                      onPressed: () => setState(() => _rating = star),
                      iconSize: 38,
                      tooltip: '$star star${star == 1 ? '' : 's'}',
                      icon: Icon(
                        star <= _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.accentAmber,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _comment,
                maxLines: 3,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText: _prompts[_rating - 1],
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

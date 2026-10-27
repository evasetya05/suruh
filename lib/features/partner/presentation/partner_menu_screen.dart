import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/datasources/local/seed/seed_categories.dart';
import '../../../domain/entities/food_item.dart';
import '../../../domain/entities/user.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/partner_bloc.dart';
import 'partner_dashboard_screen.dart';

/// Menu management: availability switches, edit and delete.
class PartnerMenuScreen extends StatelessWidget {
  const PartnerMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = context.read<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(body: ErrorView(message: 'Not signed in.'));
    }

    return BlocProvider<PartnerBloc>(
      create: (_) => buildPartnerBloc()..add(PartnerStarted(user.id)),
      child: const _PartnerMenuView(),
    );
  }
}

class _PartnerMenuView extends StatelessWidget {
  const _PartnerMenuView();

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
            appBar: AppBar(title: const Text('Menu')),
            body: const LoadingView(),
          );
        }

        // Group by category so the merchant sees the same structure customers
        // do on the restaurant page.
        final Map<String, List<FoodItem>> grouped = <String, List<FoodItem>>{};
        for (final FoodItem item in state.menu) {
          grouped.putIfAbsent(item.categoryId, () => <FoodItem>[]).add(item);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Menu (${state.menu.length})'),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push(Routes.partnerMenuEditor),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add dish'),
          ),
          body: state.menu.isEmpty
              ? EmptyView(
                  title: 'Your menu is empty',
                  message: 'Add your first dish so customers can order.',
                  icon: Icons.restaurant_menu_rounded,
                  actionLabel: 'Add a dish',
                  onAction: () => context.push(Routes.partnerMenuEditor),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                    context.gutter,
                    AppSpacing.lg,
                    context.gutter,
                    AppSpacing.huge * 2,
                  ),
                  children: <Widget>[
                    ContentContainer(
                      padded: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          for (final MapEntry<String, List<FoodItem>> entry
                              in grouped.entries) ...<Widget>[
                            SectionHeader(
                              title: _categoryName(entry.key),
                              subtitle:
                                  '${entry.value.length} dish${entry.value.length == 1 ? '' : 'es'}',
                            ),
                            for (final FoodItem item in entry.value) ...<Widget>[
                              _MenuItemCard(item: item),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            const SizedBox(height: AppSpacing.md),
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

  String _categoryName(String categoryId) => kSeedCategories
      .firstWhere(
        (dynamic c) => c.id == categoryId,
        orElse: () => kSeedCategories.first,
      )
      .name;
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppImage(
            seed: item.id,
            emoji: item.emoji,
            imageUrl: item.imageUrl,
            height: 64,
            width: 64,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Dish options',
                      padding: EdgeInsets.zero,
                      onSelected: (String action) => switch (action) {
                        'edit' => context.push(
                            '${Routes.partnerMenuEditor}?item=${item.id}',
                          ),
                        'delete' => _confirmDelete(context),
                        _ => null,
                      },
                      itemBuilder: (_) => const <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Edit dish'),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete dish'),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    Text(
                      Formatters.currency(item.effectivePrice),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: item.isOnOffer ? AppColors.danger : null,
                      ),
                    ),
                    if (item.isOnOffer) ...<Widget>[
                      const SizedBox(width: 6),
                      Text(
                        Formatters.currencyCompact(item.priceMyr),
                        style: theme.textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      item.isAvailable ? 'Available' : 'Sold out',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: item.isAvailable
                            ? AppColors.success
                            : AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Switch(
                      value: item.isAvailable,
                      onChanged: (bool value) =>
                          context.read<PartnerBloc>().add(
                                PartnerAvailabilityToggled(
                                  foodItemId: item.id,
                                  isAvailable: value,
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
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final PartnerBloc bloc = context.read<PartnerBloc>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Delete ${item.name}?'),
        content: const Text(
          'This removes the dish from your menu. Existing orders are not '
          'affected.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) bloc.add(PartnerMenuItemDeleted(item.id));
  }
}

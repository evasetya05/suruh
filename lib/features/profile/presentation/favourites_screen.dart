import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/restaurant.dart';
import '../../../domain/entities/user.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../shared/widgets/restaurant_card.dart';
import '../bloc/profile_cubit.dart';
import 'edit_profile_screen.dart';

/// Saved restaurants, with a one-tap unfavourite.
class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = context.read<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(body: ErrorView(message: 'Not signed in.'));
    }

    return BlocProvider<ProfileCubit>(
      create: (_) => buildProfileCubit()..loadFavourites(user.id),
      child: _FavouritesView(userId: user.id),
    );
  }
}

class _FavouritesView extends StatelessWidget {
  const _FavouritesView({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favourite restaurants')),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (BuildContext context, ProfileState state) {
          if (state.isLoadingFavourites && state.favourites.isEmpty) {
            return ListView.separated(
              padding: EdgeInsets.all(context.gutter),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xl),
              itemBuilder: (_, __) => const ListTileSkeleton(),
            );
          }

          if (state.favourites.isEmpty) {
            return EmptyView(
              title: 'No favourites yet',
              message:
                  'Tap the heart on any restaurant to keep it here for later.',
              icon: Icons.favorite_border_rounded,
              actionLabel: 'Browse restaurants',
              onAction: () => context.go(Routes.home),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              context.gutter,
              AppSpacing.lg,
              context.gutter,
              AppSpacing.huge,
            ),
            itemCount: state.favourites.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (BuildContext context, int i) {
              final Restaurant restaurant = state.favourites[i];
              return ContentContainer(
                padded: false,
                child: RestaurantListTile(
                  restaurant: restaurant,
                  trailing: IconButton(
                    tooltip: 'Remove from favourites',
                    onPressed: () => context
                        .read<ProfileCubit>()
                        .toggleFavourite(userId, restaurant.id),
                    icon: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

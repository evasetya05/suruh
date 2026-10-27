import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/cubit/connectivity_cubit.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/state_views.dart';
import '../../cart/bloc/cart_bloc.dart';

class _Tab {
  const _Tab({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const List<_Tab> _tabs = <_Tab>[
  _Tab(
    path: Routes.home,
    label: 'Home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
  ),
  _Tab(
    path: Routes.search,
    label: 'Search',
    icon: Icons.search_outlined,
    activeIcon: Icons.search_rounded,
  ),
  _Tab(
    path: Routes.orders,
    label: 'Orders',
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long_rounded,
  ),
  _Tab(
    path: Routes.profile,
    label: 'Account',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
  ),
];

/// Chrome around the four customer tabs.
///
/// Adapts by breakpoint: a bottom bar on phones, a `NavigationRail` on tablet
/// and desktop web. The cart button follows the same rule so it is always
/// reachable without covering content.
class AppShell extends StatelessWidget {
  const AppShell({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  int get _currentIndex {
    final int index =
        _tabs.indexWhere((_Tab t) => location.startsWith(t.path));
    return index == -1 ? 0 : index;
  }

  void _onTap(BuildContext context, int index) {
    final String target = _tabs[index].path;
    if (location == target) return;
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final bool wide = context.isWide;

    return Scaffold(
      body: Column(
        children: <Widget>[
          BlocBuilder<ConnectivityCubit, bool>(
            builder: (BuildContext context, bool online) =>
                online ? const SizedBox.shrink() : const OfflineBanner(),
          ),
          Expanded(
            child: wide
                ? Row(
                    children: <Widget>[
                      _SideRail(
                        currentIndex: _currentIndex,
                        onTap: (int i) => _onTap(context, i),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: child),
                    ],
                  )
                : child,
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : _BottomBar(
              currentIndex: _currentIndex,
              onTap: (int i) => _onTap(context, i),
            ),
      floatingActionButton: const _CartFab(),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List<Widget>.generate(_tabs.length, (int i) {
              final _Tab tab = _tabs[i];
              final bool active = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        active ? tab.activeIcon : tab.icon,
                        size: 24,
                        color: active
                            ? AppColors.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tab.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: active
                              ? AppColors.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelType: NavigationRailLabelType.all,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: AppLogo(size: 44),
      ),
      destinations: _tabs
          .map(
            (_Tab tab) => NavigationRailDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.activeIcon),
              label: Text(tab.label),
            ),
          )
          .toList(growable: false),
    );
  }
}

/// Floating basket summary. Hidden when the cart is empty so it never sits on
/// screen doing nothing.
class _CartFab extends StatelessWidget {
  const _CartFab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (CartState a, CartState b) => a.cart != b.cart,
      builder: (BuildContext context, CartState state) {
        if (state.cart.isEmpty) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          onPressed: () => context.push(Routes.cart),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: Badge(
            label: Text('${state.itemCount}'),
            backgroundColor: Colors.white,
            textColor: AppColors.primaryDark,
            child: const Icon(Icons.shopping_bag_outlined),
          ),
          label: Text(
            Formatters.currency(state.cart.total),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      },
    );
  }
}

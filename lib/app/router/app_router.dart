import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/user.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/browse/presentation/browse_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/food/presentation/food_detail_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/orders/presentation/order_tracking_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/partner/presentation/menu_editor_screen.dart';
import '../../features/partner/presentation/partner_dashboard_screen.dart';
import '../../features/partner/presentation/partner_menu_screen.dart';
import '../../features/partner/presentation/partner_orders_screen.dart';
import '../../features/profile/presentation/addresses_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/favourites_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/restaurant/presentation/restaurant_screen.dart';
import '../../features/rider/presentation/rider_dashboard_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'route_paths.dart';

/// Builds the app's route table.
///
/// The router is constructed with the [AuthBloc] rather than reading it from
/// context, so `redirect` can gate routes synchronously: a signed-out user
/// deep-linking to `/checkout` lands on `/login`, and a signed-in partner
/// cannot open the customer tabs.
GoRouter createRouter({
  required AuthBloc authBloc,
  required bool hasSeenOnboarding,
}) {
  final GlobalKey<NavigatorState> rootKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  final GlobalKey<NavigatorState> shellKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: false,
    refreshListenable: _BlocRefreshListenable(authBloc.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final AuthState auth = authBloc.state;
      final String location = state.matchedLocation;

      // Hold on the splash screen until the session has been resolved.
      if (!auth.isResolved) {
        return location == Routes.splash ? null : Routes.splash;
      }

      if (!auth.isAuthenticated) {
        if (Routes.isPublic(location) && location != Routes.splash) return null;
        return hasSeenOnboarding ? Routes.login : Routes.onboarding;
      }

      // Signed in: bounce away from the auth flow to the role's landing page.
      final String roleHome = Routes.homeFor(auth.role);
      if (Routes.isPublic(location)) return roleHome;

      // Keep each persona inside its own section of the app.
      final bool isPartnerRoute = location.startsWith(Routes.partnerDashboard);
      final bool isRiderRoute = location.startsWith(Routes.riderDashboard);

      return switch (auth.role) {
        UserRole.restaurantPartner when !isPartnerRoute => roleHome,
        UserRole.deliveryPartner when !isRiderRoute => roleHome,
        UserRole.customer when isPartnerRoute || isRiderRoute => roleHome,
        _ => null,
      };
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, __) => const RegisterScreen(),
      ),

      // --- Customer tabs ------------------------------------------------------
      ShellRoute(
        navigatorKey: shellKey,
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            AppShell(location: state.matchedLocation, child: child),
        routes: <RouteBase>[
          GoRoute(
            path: Routes.home,
            pageBuilder: (_, GoRouterState state) =>
                _fadePage(state, const HomeScreen()),
          ),
          GoRoute(
            path: Routes.search,
            pageBuilder: (_, GoRouterState state) =>
                _fadePage(state, const SearchScreen()),
          ),
          GoRoute(
            path: Routes.orders,
            pageBuilder: (_, GoRouterState state) =>
                _fadePage(state, const OrdersScreen()),
          ),
          GoRoute(
            path: Routes.profile,
            pageBuilder: (_, GoRouterState state) =>
                _fadePage(state, const ProfileScreen()),
          ),
        ],
      ),

      // --- Customer detail screens (full screen, above the shell) -------------
      GoRoute(
        path: Routes.browse,
        parentNavigatorKey: rootKey,
        builder: (_, GoRouterState state) => BrowseScreen(
          categoryId: state.uri.queryParameters['category'],
          title: state.uri.queryParameters['title'],
        ),
      ),
      GoRoute(
        path: '${Routes.restaurant}/:id',
        parentNavigatorKey: rootKey,
        builder: (_, GoRouterState state) =>
            RestaurantScreen(restaurantId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Routes.food}/:id',
        parentNavigatorKey: rootKey,
        builder: (_, GoRouterState state) =>
            FoodDetailScreen(foodItemId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.cart,
        parentNavigatorKey: rootKey,
        builder: (_, __) => const CartScreen(),
      ),
      GoRoute(
        path: Routes.checkout,
        parentNavigatorKey: rootKey,
        builder: (_, __) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '${Routes.orderTracking}/:id',
        parentNavigatorKey: rootKey,
        builder: (_, GoRouterState state) =>
            OrderTrackingScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.addresses,
        parentNavigatorKey: rootKey,
        builder: (_, __) => const AddressesScreen(),
      ),
      GoRoute(
        path: Routes.favourites,
        parentNavigatorKey: rootKey,
        builder: (_, __) => const FavouritesScreen(),
      ),
      GoRoute(
        path: Routes.editProfile,
        parentNavigatorKey: rootKey,
        builder: (_, __) => const EditProfileScreen(),
      ),

      // --- Restaurant partner -------------------------------------------------
      GoRoute(
        path: Routes.partnerDashboard,
        parentNavigatorKey: rootKey,
        builder: (_, __) => const PartnerDashboardScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'menu',
            builder: (_, __) => const PartnerMenuScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: 'editor',
                builder: (_, GoRouterState state) =>
                    MenuEditorScreen(itemId: state.uri.queryParameters['item']),
              ),
            ],
          ),
          GoRoute(
            path: 'orders',
            builder: (_, __) => const PartnerOrdersScreen(),
          ),
        ],
      ),

      // --- Delivery partner ---------------------------------------------------
      GoRoute(
        path: Routes.riderDashboard,
        parentNavigatorKey: rootKey,
        builder: (_, __) => const RiderDashboardScreen(),
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) =>
        _RouteNotFound(location: state.uri.toString()),
  );
}

/// Cross-fade between shell tabs instead of the platform push animation, which
/// looks wrong for a bottom-nav switch.
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondary,
      Widget child,
    ) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// Bridges a bloc stream to [Listenable] so GoRouter re-evaluates `redirect`
/// whenever the session changes.
class _BlocRefreshListenable extends ChangeNotifier {
  _BlocRefreshListenable(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

class _RouteNotFound extends StatelessWidget {
  const _RouteNotFound({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('🧭', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                'We could not find "$location"',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

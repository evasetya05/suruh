import '../../domain/entities/user.dart';

/// Every route path and name in one place, so navigation calls never contain a
/// string literal that can drift.
abstract final class Routes {
  // Public
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';

  // Customer shell tabs
  static const String home = '/home';
  static const String search = '/search';
  static const String orders = '/orders';
  static const String profile = '/profile';

  // Customer detail routes
  static const String restaurant = '/restaurant';
  static const String food = '/food';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderTracking = '/order';
  static const String addresses = '/profile/addresses';
  static const String favourites = '/profile/favourites';
  static const String editProfile = '/profile/edit';
  static const String browse = '/browse';

  // Restaurant partner
  static const String partnerDashboard = '/partner';
  static const String partnerMenu = '/partner/menu';
  static const String partnerOrders = '/partner/orders';
  static const String partnerMenuEditor = '/partner/menu/editor';

  // Delivery partner
  static const String riderDashboard = '/rider';

  static String restaurantDetail(String id) => '$restaurant/$id';
  static String foodDetail(String id) => '$food/$id';
  static String trackOrder(String id) => '$orderTracking/$id';
  static String browseCategory(String categoryId) =>
      '$browse?category=$categoryId';

  /// Landing route for a role right after sign-in.
  static String homeFor(UserRole role) => switch (role) {
        UserRole.customer => home,
        UserRole.restaurantPartner => partnerDashboard,
        UserRole.deliveryPartner => riderDashboard,
      };

  /// Routes reachable without a session.
  static const Set<String> publicPaths = <String>{
    splash,
    onboarding,
    login,
    register,
  };

  static bool isPublic(String location) =>
      publicPaths.any((String p) => location == p || location.startsWith('$p?'));
}

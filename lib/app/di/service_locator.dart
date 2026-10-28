import 'package:get_it/get_it.dart';

import '../../core/config/app_config.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/network/suruh_api_client.dart';
import '../../core/storage/app_database.dart';
import '../../core/storage/local_storage.dart';
import '../../data/datasources/remote/firestore_data_source.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/partner_repository_impl.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../../data/repositories/suruh_auth_repository.dart';
import '../../data/repositories/suruh_catalog_repository.dart';
import '../../data/repositories/suruh_order_repository.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/repositories/partner_repository.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/cart_usecases.dart';
import '../../domain/usecases/catalog_usecases.dart';
import '../../domain/usecases/order_usecases.dart';
import '../../domain/usecases/partner_usecases.dart';
import '../../domain/usecases/review_usecases.dart';
import '../../domain/usecases/user_usecases.dart';

final GetIt sl = GetIt.instance;

/// Composition root.
///
/// Registration order is services -> data sources -> repositories -> use cases,
/// which mirrors the dependency direction of the architecture.
abstract final class ServiceLocator {
  static Future<void> init() async {
    // --- Core services ------------------------------------------------------
    final LocalStorage storage = await LocalStorage.create();
    await AppDatabase.instance.init();

    sl
      ..registerSingleton<LocalStorage>(storage)
      ..registerSingleton<AppDatabase>(AppDatabase.instance)
      ..registerLazySingleton<ConnectivityService>(ConnectivityService.new)
      ..registerLazySingleton<SuruhApiClient>(
        () => SuruhApiClient(storage: sl<LocalStorage>()),
      );

    // --- Data sources -------------------------------------------------------
    final bool useFirebase = AppConfig.instance.backend == Backend.firebase;

    if (useFirebase) {
      sl.registerLazySingleton<FirestoreDataSource>(FirestoreDataSource.new);
    }

    // --- Repositories -------------------------------------------------------
    // Connects to the live SURUH Django REST Framework backend
    // at https://suruhjak.teknusa.com/ with SQLite local database caching.
    sl
      ..registerLazySingleton<AuthRepository>(
        () => useFirebase
            ? FirebaseAuthRepository(
                remote: sl<FirestoreDataSource>(),
                storage: sl<LocalStorage>(),
              )
            : SuruhAuthRepository(
                api: sl<SuruhApiClient>(),
                storage: sl<LocalStorage>(),
              ),
      )
      ..registerLazySingleton<CatalogRepository>(
        () => SuruhCatalogRepository(
          api: sl<SuruhApiClient>(),
          storage: sl<LocalStorage>(),
          connectivity: sl<ConnectivityService>(),
          database: sl<AppDatabase>(),
        ),
      )
      ..registerLazySingleton<CartRepository>(
        () => CartRepositoryImpl(storage: sl<LocalStorage>()),
      )
      ..registerLazySingleton<OrderRepository>(
        () => SuruhOrderRepository(
          api: sl<SuruhApiClient>(),
          storage: sl<LocalStorage>(),
          database: sl<AppDatabase>(),
        ),
      )
      ..registerLazySingleton<ReviewRepository>(
        () => ReviewRepositoryImpl(storage: sl<LocalStorage>()),
      )
      ..registerLazySingleton<UserRepository>(
        () => UserRepositoryImpl(
          api: sl<SuruhApiClient>(),
          storage: sl<LocalStorage>(),
        ),
      )
      ..registerLazySingleton<PartnerRepository>(
        () => PartnerRepositoryImpl(
          api: sl<SuruhApiClient>(),
          storage: sl<LocalStorage>(),
        ),
      );

    _registerUseCases();
  }

  static void _registerUseCases() {
    // Auth
    sl
      ..registerFactory(() => SignIn(sl<AuthRepository>()))
      ..registerFactory(() => Register(sl<AuthRepository>()))
      ..registerFactory(() => SignOut(sl<AuthRepository>()))
      ..registerFactory(() => RestoreSession(sl<AuthRepository>()))
      ..registerFactory(() => SendPasswordReset(sl<AuthRepository>()));

    // Catalogue
    sl
      ..registerFactory(() => GetHomeFeed(sl<CatalogRepository>()))
      ..registerFactory(
        () => GetRestaurantDetail(
          sl<CatalogRepository>(),
          sl<ReviewRepository>(),
        ),
      )
      ..registerFactory(
        () => GetFoodDetail(sl<CatalogRepository>(), sl<ReviewRepository>()),
      )
      ..registerFactory(() => GetFilteredRestaurants(sl<CatalogRepository>()))
      ..registerFactory(() => SearchCatalog(sl<CatalogRepository>()))
      ..registerFactory(() => RefreshCatalog(sl<CatalogRepository>()));

    // Cart
    sl
      ..registerFactory(() => LoadCart(sl<CartRepository>()))
      ..registerFactory(() => AddToCart(sl<CartRepository>()))
      ..registerFactory(() => UpdateCartQuantity(sl<CartRepository>()))
      ..registerFactory(() => RemoveCartLine(sl<CartRepository>()))
      ..registerFactory(() => ClearCart(sl<CartRepository>()))
      ..registerFactory(
        () => ApplyPromoCode(sl<CartRepository>(), sl<CatalogRepository>()),
      )
      ..registerFactory(() => RemovePromo(sl<CartRepository>()));

    // Orders
    sl
      ..registerFactory(
        () => PlaceOrder(sl<OrderRepository>(), sl<CartRepository>()),
      )
      ..registerFactory(() => GetOrderHistory(sl<OrderRepository>()))
      ..registerFactory(() => GetOrderById(sl<OrderRepository>()))
      ..registerFactory(() => WatchOrder(sl<OrderRepository>()))
      ..registerFactory(() => UpdateOrderStatus(sl<OrderRepository>()))
      ..registerFactory(() => CancelOrder(sl<OrderRepository>()))
      ..registerFactory(() => WatchRestaurantOrders(sl<OrderRepository>()))
      ..registerFactory(() => WatchRiderOrders(sl<OrderRepository>()));

    // Profile
    sl
      ..registerFactory(() => GetProfile(sl<UserRepository>()))
      ..registerFactory(() => UpdateProfile(sl<UserRepository>()))
      ..registerFactory(() => GetAddresses(sl<UserRepository>()))
      ..registerFactory(() => SaveAddress(sl<UserRepository>()))
      ..registerFactory(() => DeleteAddress(sl<UserRepository>()))
      ..registerFactory(() => SetDefaultAddress(sl<UserRepository>()))
      ..registerFactory(() => ToggleFavourite(sl<UserRepository>()))
      ..registerFactory(() => GetFavouriteRestaurants(sl<UserRepository>()));

    // Reviews
    sl
      ..registerFactory(() => GetRestaurantReviews(sl<ReviewRepository>()))
      ..registerFactory(
        () => SubmitReview(sl<ReviewRepository>(), sl<OrderRepository>()),
      );

    // Partner
    sl
      ..registerFactory(() => GetPartnerDashboard(sl<PartnerRepository>()))
      ..registerFactory(() => CreateMenuItem(sl<PartnerRepository>()))
      ..registerFactory(() => UpdateMenuItem(sl<PartnerRepository>()))
      ..registerFactory(() => DeleteMenuItem(sl<PartnerRepository>()))
      ..registerFactory(() => SetItemAvailability(sl<PartnerRepository>()))
      ..registerFactory(() => SetRestaurantOpen(sl<PartnerRepository>()));
  }

  /// Tears the graph down. Used between widget tests.
  static Future<void> reset() => sl.reset();
}

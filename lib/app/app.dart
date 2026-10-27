import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/network/connectivity_service.dart';
import '../core/storage/local_storage.dart';
import '../core/theme/app_theme.dart';
import '../domain/usecases/auth_usecases.dart';
import '../domain/usecases/cart_usecases.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/cart/bloc/cart_bloc.dart';
import 'cubit/connectivity_cubit.dart';
import 'cubit/theme_cubit.dart';
import 'di/service_locator.dart';
import 'router/app_router.dart';

/// Root widget.
///
/// Three blocs are hoisted to the very top because more than one screen depends
/// on them: the session, the basket and the theme. Everything else is created
/// per-screen so its lifetime matches the route.
class MSDevBuildEatsApp extends StatefulWidget {
  const MSDevBuildEatsApp({super.key});

  @override
  State<MSDevBuildEatsApp> createState() => _MSDevBuildEatsAppState();
}

class _MSDevBuildEatsAppState extends State<MSDevBuildEatsApp> {
  late final AuthBloc _authBloc;
  late final CartBloc _cartBloc;
  late final ThemeCubit _themeCubit;
  late final ConnectivityCubit _connectivityCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    final LocalStorage storage = sl<LocalStorage>();

    _authBloc = AuthBloc(
      signIn: sl<SignIn>(),
      register: sl<Register>(),
      signInAsDemo: sl<SignInAsDemo>(),
      signOut: sl<SignOut>(),
      restoreSession: sl<RestoreSession>(),
      sendPasswordReset: sl<SendPasswordReset>(),
    )..add(const AuthStarted());

    _cartBloc = CartBloc(
      loadCart: sl<LoadCart>(),
      addToCart: sl<AddToCart>(),
      updateQuantity: sl<UpdateCartQuantity>(),
      removeLine: sl<RemoveCartLine>(),
      clearCart: sl<ClearCart>(),
      applyPromo: sl<ApplyPromoCode>(),
      removePromo: sl<RemovePromo>(),
    )..add(const CartStarted());

    _themeCubit = ThemeCubit(storage);
    _connectivityCubit = ConnectivityCubit(sl<ConnectivityService>());

    _router = createRouter(
      authBloc: _authBloc,
      hasSeenOnboarding: storage.getBool(LocalStorage.kOnboardingSeen),
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _connectivityCubit.close();
    _themeCubit.close();
    _cartBloc.close();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<CartBloc>.value(value: _cartBloc),
        BlocProvider<ThemeCubit>.value(value: _themeCubit),
        BlocProvider<ConnectivityCubit>.value(value: _connectivityCubit),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (BuildContext context, ThemeMode mode) {
          return MaterialApp.router(
            title: AppConfig.instance.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            routerConfig: _router,
            builder: (BuildContext context, Widget? child) {
              // Cap text scaling so a large accessibility setting cannot break
              // dense list rows and price rows.
              final MediaQueryData media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: media.textScaler.clamp(
                    minScaleFactor: 0.85,
                    maxScaleFactor: 1.35,
                  ),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}

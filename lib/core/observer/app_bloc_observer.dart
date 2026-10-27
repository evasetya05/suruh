import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

/// Logs bloc lifecycle in debug builds.
///
/// Wired in `bootstrap.dart`; in release it is not installed at all, so there
/// is no runtime cost in production.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onTransition(Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
    super.onTransition(bloc, transition);
    if (!kDebugMode) return;
    developer.log(
      '${transition.event.runtimeType} -> ${transition.nextState.runtimeType}',
      name: bloc.runtimeType.toString(),
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    developer.log(
      'Unhandled bloc error',
      name: bloc.runtimeType.toString(),
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    super.onError(bloc, error, stackTrace);
  }
}

import 'dart:async';
import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/di/service_locator.dart';
import 'core/config/app_config.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/observer/app_bloc_observer.dart';
import 'firebase_options.dart';

/// Boots the app.
///
/// Order matters: config -> platform chrome -> optional Firebase -> DI graph ->
/// `runApp`. Everything that can fail is contained so a missing Firebase
/// project degrades to the demo backend instead of a black screen.
Future<void> bootstrap({AppConfig? config}) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (config != null) AppConfig.override(config);

  if (kDebugMode) Bloc.observer = const AppBlocObserver();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await _initialiseFirebase();
  await ServiceLocator.init();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    developer.log(
      'Uncaught framework error',
      name: 'MSDevBuild Eats',
      error: details.exception,
      stackTrace: details.stack,
      level: 1000,
    );
  };

  runApp(const MSDevBuildEatsApp());
}

/// Starts Firebase only when the app is configured to use it.
///
/// [DefaultFirebaseOptions.isConfigured] is `false` until `flutterfire
/// configure` has been run, so a fresh clone never tries to connect with
/// placeholder credentials.
Future<void> _initialiseFirebase() async {
  if (AppConfig.instance.backend != Backend.firebase) return;

  if (!DefaultFirebaseOptions.isConfigured) {
    developer.log(
      'Backend.firebase is selected but firebase_options.dart still holds '
      'placeholder values. Run `flutterfire configure`. Falling back to the '
      'demo backend.',
      name: 'MSDevBuild Eats',
      level: 900,
    );
    AppConfig.override(const AppConfig());
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    unawaited(PushNotificationService().initialise());
  } on Object catch (error, stackTrace) {
    developer.log(
      'Firebase initialisation failed - continuing on the demo backend.',
      name: 'MSDevBuild Eats',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    AppConfig.override(const AppConfig());
  }
}

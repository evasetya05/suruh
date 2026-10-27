import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Firebase Cloud Messaging wiring.
///
/// Registers for order-status pushes ("Your rider is on the way"), keeps the
/// device token in sync, and exposes foreground messages as a stream the UI can
/// turn into an in-app banner.
///
/// Only started when the Firebase backend is active - see `bootstrap.dart`.
class PushNotificationService {
  PushNotificationService([FirebaseMessaging? messaging])
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  /// Topic every signed-in customer subscribes to for platform-wide promos.
  static const String promoTopic = 'promotions';

  String? _token;
  String? get token => _token;

  /// Requests permission, resolves the token and subscribes to promo pushes.
  ///
  /// Safe to call more than once; failures are logged rather than thrown,
  /// because losing notifications must never block app start-up.
  Future<void> initialise() async {
    try {
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        developer.log('Push permission denied', name: 'PushNotifications');
        return;
      }

      // On web this needs the VAPID key from the Firebase console; see
      // docs/SETUP.md.
      _token = await _messaging.getToken();
      _messaging.onTokenRefresh.listen((String value) => _token = value);

      await _messaging.subscribeToTopic(promoTopic);
    } on Object catch (error, stackTrace) {
      developer.log(
        'Push notification setup failed',
        name: 'PushNotifications',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Messages received while the app is in the foreground. FCM does not display
  /// these automatically, so the UI renders its own banner.
  Stream<RemoteMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage;

  /// Fires when a notification is tapped and the app was in the background.
  /// The payload carries `orderId`, which the router uses to deep-link into
  /// order tracking.
  Stream<RemoteMessage> get onNotificationTap =>
      FirebaseMessaging.onMessageOpenedApp;

  /// The notification that cold-started the app, if any.
  Future<RemoteMessage?> get initialMessage => _messaging.getInitialMessage();

  /// Per-order topic so a rider and a customer both get status updates without
  /// the server tracking individual device tokens.
  Future<void> subscribeToOrder(String orderId) =>
      _messaging.subscribeToTopic('order_$orderId');

  Future<void> unsubscribeFromOrder(String orderId) =>
      _messaging.unsubscribeFromTopic('order_$orderId');
}

/// Background handler. Must be a top-level function - FCM spawns a separate
/// isolate for it, so nothing from the app's object graph is available here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    developer.log(
      'Background message: ${message.messageId}',
      name: 'PushNotifications',
    );
  }
}

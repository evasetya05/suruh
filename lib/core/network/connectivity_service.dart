import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Reports whether the device currently has a network path.
///
/// The app degrades gracefully rather than blocking: repositories fall back to
/// the local cache and the UI shows an offline banner.
class ConnectivityService {
  ConnectivityService([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// How long to wait for the platform channel before giving up.
  ///
  /// Without this an unresponsive channel (a cold plugin, a test environment
  /// with no implementation registered) would leave the future hanging and
  /// every catalogue read blocked behind it.
  static const Duration _probeTimeout = Duration(milliseconds: 800);

  Future<bool> get isOnline async {
    try {
      final List<ConnectivityResult> result = await _connectivity
          .checkConnectivity()
          .timeout(_probeTimeout);
      return _isOnline(result);
    } on Object {
      // Timed out, or the platform channel is unavailable. Assume online so we
      // never falsely degrade the experience - the request that follows will
      // fail on its own if there really is no connection, and the repository
      // falls back to cache at that point.
      return true;
    }
  }

  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_isOnline).distinct();

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.isNotEmpty &&
      !results.every((ConnectivityResult r) => r == ConnectivityResult.none);
}

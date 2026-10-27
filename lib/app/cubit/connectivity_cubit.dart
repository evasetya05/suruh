import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../core/network/connectivity_service.dart';

/// Tracks online/offline so the shell can show a banner and repositories can
/// explain why they served cached data.
class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit(this._service) : super(true) {
    _subscription = _service.onStatusChange.listen(emit);
    unawaited(_service.isOnline.then(emit));
  }

  final ConnectivityService _service;
  StreamSubscription<bool>? _subscription;

  bool get isOffline => !state;

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

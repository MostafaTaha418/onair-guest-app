import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class ConnectivityState {
  const ConnectivityState({required this.isOnline});

  final bool isOnline;
}

/// Only controls the offline banner. Request outcomes remain server-owned.
final class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity(),
      super(const ConnectivityState(isOnline: true)) {
    _subscription = _connectivity.onConnectivityChanged.listen(_update);
    unawaited(_connectivity.checkConnectivity().then(_update));
  }

  final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  void _update(List<ConnectivityResult> results) {
    if (!isClosed) {
      emit(
        ConnectivityState(isOnline: !results.contains(ConnectivityResult.none)),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}

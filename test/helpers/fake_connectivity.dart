import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mocktail/mocktail.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';

class FakeConnectivitySource extends Mock implements Connectivity {}

/// A [ConnectivityCubit] driven by a controllable stream, so tests can flip
/// the app between online and offline.
final class FakeConnectivity {
  FakeConnectivity() {
    when(() => connectivity.onConnectivityChanged).thenAnswer(
      (_) => controller.stream,
    );
    when(connectivity.checkConnectivity).thenAnswer(
      (_) async => <ConnectivityResult>[ConnectivityResult.wifi],
    );
  }

  final FakeConnectivitySource connectivity = FakeConnectivitySource();
  final StreamController<List<ConnectivityResult>> controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  ConnectivityCubit createCubit() =>
      ConnectivityCubit(connectivity: connectivity);

  void goOffline() => controller.add(const [ConnectivityResult.none]);

  void goOnline() => controller.add(const [ConnectivityResult.wifi]);

  void dispose() => controller.close();
}

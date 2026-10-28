import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/design_system/components/state_views.dart';

import 'test_app_harness.dart';

final class _Connectivity extends Mock implements Connectivity {}

void main() {
  testWidgets(
    'offline banner appears and disables server action until online',
    (tester) async {
      final updates = StreamController<List<ConnectivityResult>>.broadcast();
      addTearDown(updates.close);
      final connectivity = _Connectivity();
      when(
        () => connectivity.onConnectivityChanged,
      ).thenAnswer((_) => updates.stream);
      when(
        connectivity.checkConnectivity,
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      final cubit = ConnectivityCubit(connectivity: connectivity);
      addTearDown(cubit.close);
      await pumpVisitorApp(tester, connectivityCubit: cubit);
      expect(find.byType(OfflineBanner), findsNothing);

      updates.add([ConnectivityResult.none]);
      await tester.pumpAndSettle();
      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('notifications-button')),
            )
            .onPressed,
        isNull,
      );

      updates.add([ConnectivityResult.wifi]);
      await tester.pumpAndSettle();
      expect(find.byType(OfflineBanner), findsNothing);
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('notifications-button')),
            )
            .onPressed,
        isNotNull,
      );
    },
  );
}

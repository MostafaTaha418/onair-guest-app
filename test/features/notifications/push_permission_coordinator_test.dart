import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/push/notification_permission.dart';
import 'package:on_air/core/push/push_token_source.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/account_gate/application/device_registration_service.dart';
import 'package:on_air/features/account_gate/data/device_repository.dart';
import 'package:on_air/features/notifications/presentation/push_permission_coordinator.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class _RecordingDevices implements DeviceTokenRepository {
  final List<({String token, String locale})> registered = [];

  @override
  Future<void> registerDeviceToken({
    required String token,
    required DevicePlatform platform,
    required String locale,
  }) async {
    registered.add((token: token, locale: locale));
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {}
}

final class _FixedTokens implements PushTokenSource {
  const _FixedTokens(this.token);

  final String token;

  @override
  Future<String?> currentToken() async => token;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();
}

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  Future<
    (
      PushPermissionCoordinator,
      FakeNotificationPermission,
      _RecordingDevices,
      SharedPreferences,
    )
  >
  buildHarness({PushPermission? current}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final permission = FakeNotificationPermission(
      current: current ?? PushPermission.notDetermined,
    );
    final devices = _RecordingDevices();
    final service = DeviceRegistrationService(
      devices: devices,
      pushTokens: const _FixedTokens('token-1'),
      platform: DevicePlatform.android,
      locale: () => 'ar',
    );
    final coordinator = PushPermissionCoordinator(
      permission: permission,
      devices: service,
      prefs: () async => prefs,
    );
    return (coordinator, permission, devices, prefs);
  }

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: OnAirTheme.light,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: TextButton(
            key: const ValueKey('host-ask'),
            onPressed: () {},
            child: const Text('host'),
          ),
        ),
      ),
    );
  }

  testWidgets('notDetermined and an unset flag shows the sheet once', (
    tester,
  ) async {
    await pumpHost(tester);
    final (coordinator, permission, _, prefs) = await buildHarness();

    final context = tester.element(find.text('host'));
    final asking = coordinator.maybeAskAfterFirstSuccess(context);
    await tester.pumpAndSettle();
    expect(find.text(l10n.pushPermissionTitle), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('push-enable')));
    await asking;
    await tester.pumpAndSettle();

    expect(permission.requestCalls, 1);
    expect(prefs.getBool(PushPermissionCoordinator.askedKey), isTrue);

    // A second call never shows the sheet again.
    await coordinator.maybeAskAfterFirstSuccess(
      tester.element(find.text('host')),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.pushPermissionTitle), findsNothing);
  });

  testWidgets('"Enable" requests and registers the device', (tester) async {
    await pumpHost(tester);
    final (coordinator, permission, devices, _) = await buildHarness();

    final context = tester.element(find.text('host'));
    final asking = coordinator.maybeAskAfterFirstSuccess(context);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('push-enable')));
    await asking;
    await tester.pumpAndSettle();

    expect(permission.requestCalls, 1);
    expect(devices.registered, hasLength(1));
    expect(devices.registered.single.token, 'token-1');
  });

  testWidgets('"Later" sets the flag without requesting', (tester) async {
    await pumpHost(tester);
    final (coordinator, permission, devices, prefs) = await buildHarness();

    final context = tester.element(find.text('host'));
    final asking = coordinator.maybeAskAfterFirstSuccess(context);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('push-later')));
    await asking;
    await tester.pumpAndSettle();

    expect(permission.requestCalls, 0);
    expect(prefs.getBool(PushPermissionCoordinator.askedKey), isTrue);
    expect(devices.registered, isEmpty);
  });

  testWidgets('a decided permission never shows the sheet', (tester) async {
    await pumpHost(tester);

    final (deniedCoordinator, deniedPermission, _, _) = await buildHarness(
      current: PushPermission.denied,
    );
    await deniedCoordinator.maybeAskAfterFirstSuccess(
      tester.element(find.text('host')),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.pushPermissionTitle), findsNothing);
    expect(deniedPermission.requestCalls, 0);

    final (grantedCoordinator, grantedPermission, _, _) = await buildHarness(
      current: PushPermission.granted,
    );
    await grantedCoordinator.maybeAskAfterFirstSuccess(
      tester.element(find.text('host')),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.pushPermissionTitle), findsNothing);
    expect(grantedPermission.requestCalls, 0);
  });
}

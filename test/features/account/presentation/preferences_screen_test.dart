import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/push/notification_permission.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/account/domain/notification_preference.dart';
import 'package:on_air/features/account/presentation/notifications/preferences_cubit.dart';
import 'package:on_air/features/account/presentation/notifications/preferences_screen.dart';
import 'package:on_air/features/notifications/presentation/push_permission_coordinator.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_connectivity.dart';

class _Repository extends Fake implements AccountRepository {}

const _preferences = [
  NotificationPreference(
    key: 'booking',
    labelKey: 'notifCategoryBooking',
    isMandatory: true,
    channels: {
      NotificationChannel.push: PreferenceChannel(enabled: true),
      NotificationChannel.email: PreferenceChannel(enabled: true),
    },
  ),
  NotificationPreference(
    key: 'support',
    labelKey: 'notifCategorySupport',
    isMandatory: false,
    channels: {
      NotificationChannel.push: PreferenceChannel(enabled: true),
      NotificationChannel.email: PreferenceChannel(enabled: false),
    },
  ),
];

void main() {
  Future<({FakeNotificationPermission permission, FakeConnectivity network})>
  pump(
    WidgetTester tester, {
    bool blocked = false,
    bool online = true,
    List<NotificationPreference> preferences = _preferences,
  }) async {
    final permission = FakeNotificationPermission(
      current: blocked ? PushPermission.denied : PushPermission.granted,
    );
    final coordinator = PushPermissionCoordinator(
      permission: permission,
      devices: null,
    );
    final cubit = PreferencesCubit.seeded(
      _Repository(),
      PreferencesReady(
        preferences: preferences,
        deviceNotificationsBlocked: blocked,
      ),
    );
    final network = FakeConnectivity();
    final connection = network.createCubit();
    if (!online) network.goOffline();
    addTearDown(cubit.close);
    addTearDown(connection.close);
    addTearDown(network.dispose);
    await tester.pumpWidget(
      RepositoryProvider.value(
        value: coordinator,
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider<ConnectivityCubit>.value(value: connection),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: OnAirTheme.light,
            home: const PreferencesScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (permission: permission, network: network);
  }

  testWidgets('mandatory rows are locked, on, disabled and announced', (
    tester,
  ) async {
    await pump(tester);
    final push = tester.widget<Switch>(
      find.byKey(const ValueKey('preference-switch-booking-push')),
    );
    expect(push.value, isTrue);
    expect(push.onChanged, isNull);
    expect(
      find.byKey(const ValueKey('preference-lock-booking')),
      findsOneWidget,
    );
    final l10n = lookupAppLocalizations(const Locale('ar'));
    expect(find.text(l10n.prefsMandatory), findsOneWidget);
    expect(find.bySemanticsLabel(l10n.prefsMandatoryLabel), findsWidgets);
  });

  testWidgets('blocked banner opens notification settings', (tester) async {
    final result = await pump(tester, blocked: true);
    final l10n = lookupAppLocalizations(const Locale('ar'));
    expect(
      find.byKey(const ValueKey('device-notifications-blocked')),
      findsOneWidget,
    );
    await tester.tap(find.text(l10n.prefsOpenSettings));
    await tester.pump();
    expect(result.permission.openSettingsCalls, 1);
  });

  testWidgets('offline disables preference switches', (tester) async {
    await pump(tester, online: false);
    final push = tester.widget<Switch>(
      find.byKey(const ValueKey('preference-switch-support-push')),
    );
    expect(push.onChanged, isNull);
  });

  testWidgets(
    'empty server catalog shows a recoverable error, not a blank page',
    (
      tester,
    ) async {
      await pump(tester, preferences: const []);
      final l10n = lookupAppLocalizations(const Locale('ar'));

      expect(find.text(l10n.prefsUnavailable), findsOneWidget);
      expect(find.text(l10n.retry), findsOneWidget);
    },
  );
}

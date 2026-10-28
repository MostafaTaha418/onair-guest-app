import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/app.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/config/version_gate.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/features/app_update/presentation/update_required_screen.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/search/domain/last_search_store.dart';

import '../helpers/fake_app_config_repository.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_listings_repository.dart';

void main() {
  testWidgets('app starts in Arabic RTL with a visitor route', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);
    final config = FakeAppConfigRepository(
      const AppConfig(
        minSupportedBuildAndroid: 1,
        minSupportedBuildIos: 1,
        supportPhone: '+201000000000',
        currentTermsVersion: 'v1',
      ),
    );
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: repository),
          RepositoryProvider<AppConfigSource>.value(value: config),
          RepositoryProvider<AppLogger>.value(value: AppLogger(sink: (_) {})),
          RepositoryProvider<ListingsRepository>.value(
            value: FakeListingsRepository(),
          ),
          RepositoryProvider<LastSearchStore>.value(value: LastSearchStore()),
        ],
        child: const OnAirApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('الرئيسية'))),
      TextDirection.rtl,
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('ar'),
    );
  });

  testWidgets('an active version gate blocks the app with update-required', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);
    final config = FakeAppConfigRepository(
      const AppConfig(
        minSupportedBuildAndroid: 100,
        minSupportedBuildIos: 100,
        supportPhone: '+201000000000',
        currentTermsVersion: 'v1',
      ),
    );
    final gate = VersionGate(
      configSource: config,
      installedBuildSource: () async => 1,
      platformResolver: () => TargetPlatform.android,
      observeLifecycle: false,
    );
    addTearDown(gate.dispose);
    await gate.check();
    expect(gate.updateRequired, isTrue);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: repository),
          RepositoryProvider<AppConfigSource>.value(value: config),
          RepositoryProvider<AppLogger>.value(value: AppLogger(sink: (_) {})),
          RepositoryProvider<ListingsRepository>.value(
            value: FakeListingsRepository(),
          ),
          RepositoryProvider<LastSearchStore>.value(value: LastSearchStore()),
        ],
        child: OnAirApp(versionGate: gate),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(UpdateRequiredScreen), findsOneWidget);
    expect(find.text('الرئيسية'), findsNothing);
  });
}

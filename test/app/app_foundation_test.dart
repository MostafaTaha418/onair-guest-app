import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/app.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';

import '../helpers/fake_app_config_repository.dart';
import '../helpers/fake_auth_repository.dart';

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
}

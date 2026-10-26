import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/app.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';

import '../helpers/fake_app_config_repository.dart';
import '../helpers/fake_auth_repository.dart';

Future<void> pumpVisitorApp(
  WidgetTester tester, {
  ConnectivityCubit? connectivityCubit,
}) async {
  final auth = FakeAuthRepository();
  addTearDown(auth.dispose);
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
        RepositoryProvider<AuthRepository>.value(value: auth),
        RepositoryProvider<AppConfigSource>.value(value: config),
        RepositoryProvider<AppLogger>.value(value: AppLogger(sink: (_) {})),
      ],
      child: OnAirApp(connectivityCubit: connectivityCubit),
    ),
  );
  await tester.pumpAndSettle();
}

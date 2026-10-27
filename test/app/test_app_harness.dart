import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/app.dart';
import 'package:on_air/app/router/incoming_links.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';

import '../helpers/fake_app_config_repository.dart';
import '../helpers/fake_auth_repository.dart';

Future<void> pumpVisitorApp(
  WidgetTester tester, {
  ConnectivityCubit? connectivityCubit,
}) async {
  await _pumpApp(tester, connectivityCubit: connectivityCubit);
}

Future<void> pumpSignedInApp(WidgetTester tester) async {
  await _pumpApp(
    tester,
    account: GuestAccount(
      id: 'guest',
      phone: '+201012345678',
      phoneVerified: true,
      fullName: 'Guest',
      acceptedTermsVersion: 'v1',
      acceptedTermsAt: DateTime.utc(2026),
    ),
  );
}

Future<void> pumpVisitorAppWithLinks(
  WidgetTester tester, {
  required UriLinkSource uriLinkSource,
  required String linkDomain,
}) async {
  await _pumpApp(
    tester,
    uriLinkSource: uriLinkSource,
    linkDomain: linkDomain,
  );
}

Future<void> _pumpApp(
  WidgetTester tester, {
  ConnectivityCubit? connectivityCubit,
  GuestAccount? account,
  UriLinkSource? uriLinkSource,
  String? linkDomain,
}) async {
  final auth = FakeAuthRepository()..account = account;
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
      child: OnAirApp(
        connectivityCubit: connectivityCubit,
        uriLinkSource: uriLinkSource,
        linkDomain: linkDomain,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

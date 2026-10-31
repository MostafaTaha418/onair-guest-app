import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/app.dart';
import 'package:on_air/app/router/incoming_links.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/config/version_gate.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/payments/in_app_browser.dart';
import 'package:on_air/core/push/notification_permission.dart';
import 'package:on_air/core/push/push_messages.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/core/share/share_service.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/home/data/home_feed_cache.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/notifications/presentation/push_permission_coordinator.dart';
import 'package:on_air/features/search/domain/last_search_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/controllable_push_message_source.dart';
import '../helpers/fake_app_config_repository.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_booking_backend.dart';
import '../helpers/fake_listings_repository.dart';
import '../helpers/fake_share_service.dart';

Future<void> pumpVisitorApp(
  WidgetTester tester, {
  ConnectivityCubit? connectivityCubit,
  VersionGate? versionGate,
  ListingsRepository? listingsRepository,
  InAppBrowser? inAppBrowser,
}) async {
  await _pumpApp(
    tester,
    connectivityCubit: connectivityCubit,
    versionGate: versionGate,
    listingsRepository: listingsRepository,
    inAppBrowser: inAppBrowser,
  );
}

Future<void> pumpSignedInApp(
  WidgetTester tester, {
  ListingsRepository? listingsRepository,
  InAppBrowser? inAppBrowser,
}) async {
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
    listingsRepository: listingsRepository,
    inAppBrowser: inAppBrowser,
  );
}

Future<void> pumpVisitorAppWithLinks(
  WidgetTester tester, {
  required UriLinkSource uriLinkSource,
  required String linkDomain,
  ListingsRepository? listingsRepository,
}) async {
  await _pumpApp(
    tester,
    uriLinkSource: uriLinkSource,
    linkDomain: linkDomain,
    listingsRepository: listingsRepository,
  );
}

Future<void> _pumpApp(
  WidgetTester tester, {
  ConnectivityCubit? connectivityCubit,
  GuestAccount? account,
  UriLinkSource? uriLinkSource,
  String? linkDomain,
  VersionGate? versionGate,
  ListingsRepository? listingsRepository,
  InAppBrowser? inAppBrowser,
}) async {
  final auth = FakeAuthRepository()..account = account;
  addTearDown(auth.dispose);
  final bookingBackend = FakeBookingBackend();
  addTearDown(bookingBackend.dispose);
  final config = FakeAppConfigRepository(
    const AppConfig(
      minSupportedBuildAndroid: 1,
      minSupportedBuildIos: 1,
      supportPhone: '+201000000000',
      currentTermsVersion: 'v1',
    ),
  );
  SharedPreferences.setMockInitialValues({});
  final pushSource = ControllablePushMessageSource();
  addTearDown(pushSource.dispose);
  final listings = listingsRepository ?? FakeListingsRepository();
  final cacheDirectory = Directory.systemTemp.createTempSync(
    'on_air_test_cache',
  );
  addTearDown(() => cacheDirectory.deleteSync(recursive: true));
  final cache = JsonFileCache(
    directory: cacheDirectory,
    fileName: 'discovery_cache.json',
    schema: 1,
  );
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: auth),
        RepositoryProvider<AppConfigSource>.value(value: config),
        RepositoryProvider<AppLogger>.value(value: AppLogger(sink: (_) {})),
        RepositoryProvider<ListingsRepository>.value(value: listings),
        RepositoryProvider<JsonFileCache>.value(value: cache),
        RepositoryProvider<ReferenceDataCache>.value(
          value: ReferenceDataCache(listings, cache),
        ),
        RepositoryProvider<LastSearchStore>.value(value: LastSearchStore()),
        RepositoryProvider<HomeFeedCache>.value(value: HomeFeedCache(cache)),
        RepositoryProvider<NotificationSignalSource>.value(
          value: ControllableNotificationSignalSource(),
        ),
        RepositoryProvider<ShareService>.value(value: FakeShareService()),
        RepositoryProvider<ShareLinks>.value(
          value: const ShareLinks(linkDomain: 'on-air.website'),
        ),
        ...bookingBackend.appProviders(),
        RepositoryProvider<NotificationPermission>.value(
          value: FakeNotificationPermission(),
        ),
        RepositoryProvider<PushMessageSource>.value(value: pushSource),
        RepositoryProvider<PushPermissionCoordinator>.value(
          value: PushPermissionCoordinator(
            permission: FakeNotificationPermission(),
            devices: null,
          ),
        ),
      ],
      child: OnAirApp(
        connectivityCubit: connectivityCubit,
        uriLinkSource: uriLinkSource,
        linkDomain: linkDomain,
        versionGate: versionGate,
        inAppBrowser: inAppBrowser,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

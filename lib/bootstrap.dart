import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/app/app.dart';
import 'package:on_air/app/router/incoming_links.dart';
import 'package:on_air/core/auth/secure_session_storage.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/env/env_config.dart';
import 'package:on_air/core/env/firebase_options_production.dart'
    as production_firebase;
import 'package:on_air/core/env/firebase_options_staging.dart'
    as staging_firebase;
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/push/firebase_push_token_source.dart';
import 'package:on_air/core/push/push_token_source.dart';
import 'package:on_air/core/share/share_service.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/features/account_gate/application/device_registration_service.dart';
import 'package:on_air/features/account_gate/application/personal_data_resetter.dart';
import 'package:on_air/features/account_gate/application/sign_out_service.dart';
import 'package:on_air/features/account_gate/data/device_repository.dart';
import 'package:on_air/features/account_gate/data/mock_device_repository.dart';
import 'package:on_air/features/account_gate/presentation/session_listener.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/auth/data/profile_repository.dart';
import 'package:on_air/features/auth/data/supabase_auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/home/data/home_feed_cache.dart';
import 'package:on_air/features/listings/data/mock_listings_repository.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/data/supabase_listings_repository.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/search/domain/last_search_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrap(String flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  final environment = EnvConfig.fromEnvironment();
  final uriLinkSource = AppLinksUriSource();
  if (environment.flavor != flavor) {
    throw StateError('Entrypoint flavor does not match FLAVOR');
  }
  CairoTime.initialize();
  final logger = AppLogger();
  FlutterError.onError = (details) {
    logger.error('${details.exception}\n${details.stack}');
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error('$error\n$stack');
    return true;
  };
  final backend = switch (environment.backendMode) {
    BackendMode.remote => await _remoteBackend(environment),
    BackendMode.mock => _mockBackend(),
  };
  final configSource = backend.config;
  final authRepository = backend.auth;
  final pushTokens = backend.pushTokens;
  final devices = backend.devices;
  final deviceRegistrationService = DeviceRegistrationService(
    devices: devices,
    pushTokens: pushTokens,
    platform: defaultTargetPlatform == TargetPlatform.iOS
        ? DevicePlatform.ios
        : DevicePlatform.android,
    locale: () => 'ar',
  );
  final signOutCoordinator = SignOutService(
    devices: devices,
    auth: authRepository,
    pushTokens: pushTokens,
    caches: AppConfigCacheCleaner(configSource),
    preferences: const SharedPreferencesCleaner(),
  );
  final sessionEventSource = backend.sessionEvents;
  final discoveryCache = await JsonFileCache.appSupport(
    fileName: 'discovery_cache.json',
    schema: 1,
  );
  final referenceData = ReferenceDataCache(backend.listings, discoveryCache);
  final lastSearchStore = LastSearchStore();
  final homeFeedCache = HomeFeedCache(discoveryCache);
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<EnvConfig>.value(value: environment),
        RepositoryProvider<AppLogger>.value(value: logger),
        RepositoryProvider<AppConfigSource>.value(value: configSource),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<PushTokenSource>.value(value: pushTokens),
        RepositoryProvider<DeviceTokenRepository>.value(value: devices),
        RepositoryProvider<ListingsRepository>.value(value: backend.listings),
        RepositoryProvider<JsonFileCache>.value(value: discoveryCache),
        RepositoryProvider<ReferenceDataCache>.value(value: referenceData),
        RepositoryProvider<LastSearchStore>.value(value: lastSearchStore),
        RepositoryProvider<HomeFeedCache>.value(value: homeFeedCache),
        RepositoryProvider<ShareService>.value(
          value: const SharePlusShareService(),
        ),
        RepositoryProvider<ShareLinks>.value(
          value: ShareLinks(linkDomain: environment.linkDomain),
        ),
      ],
      child: OnAirApp(
        signOutCoordinator: signOutCoordinator,
        sessionEventSource: sessionEventSource,
        personalDataResetter: const NoopPersonalDataResetter(),
        deviceRegistrationService: deviceRegistrationService,
        uriLinkSource: uriLinkSource,
        linkDomain: environment.linkDomain,
      ),
    ),
  );
}

/// The repositories the app runs on, chosen by `BACKEND_MODE`
/// (Guest Plan §2.6). Screens only see the interfaces.
typedef _Backend = ({
  AppConfigSource config,
  AuthRepository auth,
  PushTokenSource pushTokens,
  DeviceTokenRepository devices,
  SessionEventSource sessionEvents,
  ListingsRepository listings,
});

Future<_Backend> _remoteBackend(EnvConfig environment) async {
  final firebaseOptions = switch (environment.flavor) {
    'staging' => staging_firebase.DefaultFirebaseOptions.currentPlatform,
    'production' => production_firebase.DefaultFirebaseOptions.currentPlatform,
    _ => throw StateError('Unsupported Firebase flavor: ${environment.flavor}'),
  };
  await Firebase.initializeApp(options: firebaseOptions);
  await Supabase.initialize(
    url: environment.supabaseUrl,
    publishableKey: environment.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(localStorage: SecureSessionStorage()),
  );
  final client = Supabase.instance.client;
  return (
    config: AppConfigRepository(client),
    auth: SupabaseAuthRepository(
      SupabasePhoneAuthClient(client.auth),
      ProfileRepository(client),
    ),
    pushTokens: FirebasePushTokenSource(),
    devices: DeviceRepository(client),
    sessionEvents: SupabaseSessionEventSource(client.auth),
    listings: SupabaseListingsRepository(
      rpc: (fn, params) => client.rpc<dynamic>(fn, params: params),
    ),
  );
}

/// In-memory backend: no Supabase, Node, or Firebase connection.
_Backend _mockBackend() => (
  config: const MockAppConfigSource(),
  auth: MockAuthRepository(),
  pushTokens: const NoopPushTokenSource(),
  devices: MockDeviceTokenRepository(),
  sessionEvents: const NoopSessionEventSource(),
  listings: MockListingsRepository(),
);

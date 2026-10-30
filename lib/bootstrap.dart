import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/app/app.dart';
import 'package:on_air/app/router/incoming_links.dart';
import 'package:on_air/core/api/generated/export.dart';
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
import 'package:on_air/core/network/dio_factory.dart';
import 'package:on_air/core/network/supabase_token_source.dart';
import 'package:on_air/core/push/firebase_push_token_source.dart';
import 'package:on_air/core/push/push_token_source.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/core/share/share_service.dart';
import 'package:on_air/core/storage/secure_store.dart';
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
import 'package:on_air/features/booking/data/payment_attempt_store.dart';
import 'package:on_air/features/booking/data/supabase_booking_flow_repository.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/bookings/data/arrival_instructions_store.dart';
import 'package:on_air/features/bookings/data/bookings_cache.dart';
import 'package:on_air/features/bookings/data/mock_booking_server.dart';
import 'package:on_air/features/bookings/data/supabase_bookings_repository.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/home/data/home_feed_cache.dart';
import 'package:on_air/features/listings/data/mock_listings_repository.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/data/supabase_listings_repository.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/notifications/data/supabase_notifications_repository.dart';
import 'package:on_air/features/notifications/domain/notifications_repository.dart';
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
  final bookingsFileCache = await JsonFileCache.appSupport(
    fileName: 'bookings_cache.json',
    schema: 1,
  );
  final paymentAttemptStore = PaymentAttemptStore(backend.secureStore);
  final arrivalInstructions = ArrivalInstructionsStore(backend.secureStore);
  final bookingsCache = BookingsCache(bookingsFileCache);
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
        RepositoryProvider<BookingsRepository>.value(value: backend.bookings),
        RepositoryProvider<BookingFlowRepository>.value(
          value: backend.bookingFlow,
        ),
        RepositoryProvider<NotificationsRepository>.value(
          value: backend.notifications,
        ),
        RepositoryProvider<NotificationSignalSource>.value(
          value: backend.signals,
        ),
        RepositoryProvider<SecureStore>.value(value: backend.secureStore),
        RepositoryProvider<PaymentAttemptStore>.value(
          value: paymentAttemptStore,
        ),
        RepositoryProvider<ArrivalInstructionsStore>.value(
          value: arrivalInstructions,
        ),
        RepositoryProvider<BookingsCache>.value(value: bookingsCache),
        RepositoryProvider<BookingActionRegistry>.value(
          value: BookingActionRegistry.g2(),
        ),
        RepositoryProvider<MockBookingServer?>.value(
          value: backend.mockServer,
        ),
      ],
      child: OnAirApp(
        signOutCoordinator: signOutCoordinator,
        sessionEventSource: sessionEventSource,
        personalDataResetter: CompositePersonalDataResetter([
          bookingsCache.clear,
          paymentAttemptStore.clear,
          arrivalInstructions.clearAll,
          backend.signals.stop,
        ]),
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
  BookingsRepository bookings,
  BookingFlowRepository bookingFlow,
  NotificationsRepository notifications,
  NotificationSignalSource signals,
  SecureStore secureStore,
  MockBookingServer? mockServer,
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
  Future<dynamic> rpc(String fn, Map<String, dynamic> params) =>
      client.rpc<dynamic>(fn, params: params);
  final dio = createNodeDio(
    baseUrl: environment.nodeApiBaseUrl,
    tokens: SupabaseTokenSource(client),
  );
  return (
    config: AppConfigRepository(client),
    auth: SupabaseAuthRepository(
      SupabasePhoneAuthClient(client.auth),
      ProfileRepository(client),
    ),
    pushTokens: FirebasePushTokenSource(),
    devices: DeviceRepository(client),
    sessionEvents: SupabaseSessionEventSource(client.auth),
    listings: SupabaseListingsRepository(rpc: rpc),
    bookings: SupabaseBookingsRepository(rpc: rpc),
    bookingFlow: SupabaseBookingFlowRepository(
      rpc: rpc,
      node: FallbackClient(dio),
    ),
    notifications: SupabaseNotificationsRepository(rpc: rpc),
    signals: SupabaseNotificationSignalSource(client),
    secureStore: FlutterSecureStore(),
    mockServer: null,
  );
}

/// In-memory backend: no Supabase, Node, or Firebase connection.
_Backend _mockBackend() {
  final listings = MockListingsRepository();
  final signals = ControllableNotificationSignalSource();
  final server = MockBookingServer(listings: listings, signals: signals);
  return (
    config: const MockAppConfigSource(),
    auth: MockAuthRepository(),
    pushTokens: const NoopPushTokenSource(),
    devices: MockDeviceTokenRepository(),
    sessionEvents: const NoopSessionEventSource(),
    listings: listings,
    bookings: server,
    bookingFlow: server,
    notifications: server,
    signals: signals,
    secureStore: InMemorySecureStore(),
    mockServer: server,
  );
}

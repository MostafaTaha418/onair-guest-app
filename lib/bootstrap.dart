import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:on_air/app/app.dart';
import 'package:on_air/app/router/incoming_links.dart';
import 'package:on_air/core/api/generated/export.dart';
import 'package:on_air/core/auth/secure_session_storage.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/device/app_attestation.dart';
import 'package:on_air/core/device/device_identity.dart';
import 'package:on_air/core/env/env_config.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/network/dio_factory.dart';
import 'package:on_air/core/network/supabase_token_source.dart';
import 'package:on_air/core/push/firebase_push_token_source.dart';
import 'package:on_air/core/push/notification_permission.dart';
import 'package:on_air/core/push/push_messages.dart';
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
import 'package:on_air/features/auth/data/social_credential_source.dart';
import 'package:on_air/features/auth/data/supabase_auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/booking/data/payment_attempt_store.dart';
import 'package:on_air/features/booking/data/supabase_booking_flow_repository.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/bookings/data/arrival_instructions_store.dart';
import 'package:on_air/features/bookings/data/bookings_cache.dart';
import 'package:on_air/features/bookings/data/mock_booking_server.dart';
import 'package:on_air/features/bookings/data/mock_home_feed_with_bookings.dart';
import 'package:on_air/features/bookings/data/supabase_bookings_repository.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/favorites/data/memory_favorites_repository.dart';
import 'package:on_air/features/favorites/data/supabase_favorites_repository.dart';
import 'package:on_air/features/home/data/home_feed_cache.dart';
import 'package:on_air/features/listings/data/mock_listings_repository.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/data/supabase_listings_repository.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/notifications/data/supabase_notifications_repository.dart';
import 'package:on_air/features/notifications/domain/notifications_repository.dart';
import 'package:on_air/features/notifications/presentation/push_permission_coordinator.dart';
import 'package:on_air/features/search/domain/last_search_store.dart';
import 'package:on_air/features/stay/data/action_attempt_store.dart';
import 'package:on_air/features/stay/data/mock_stay_server.dart';
import 'package:on_air/features/stay/data/supabase_stay_repository.dart';
import 'package:on_air/features/stay/domain/stay_repository.dart';
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
  final deviceIdentity = backend.deviceIdentity;
  final favorites = environment.backendMode == BackendMode.remote
      ? SupabaseFavoritesRepository(Supabase.instance.client)
      : MemoryFavoritesRepository();
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
    // The provider session is cleared too; the device abuse key stays (R13).
    socialSignOut: environment.backendMode == BackendMode.remote
        ? GoogleSignIn.instance.signOut
        : null,
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
  final actionAttempts = ActionAttemptStore(backend.secureStore);
  final bookingsCache = BookingsCache(bookingsFileCache);
  final notificationPermission = backend.permission;
  final pushPermissionCoordinator = PushPermissionCoordinator(
    permission: notificationPermission,
    devices: deviceRegistrationService,
  );
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<EnvConfig>.value(value: environment),
        RepositoryProvider<AppLogger>.value(value: logger),
        // Needed later by the mock OTP server (US5) and the send interceptor.
        RepositoryProvider<DeviceIdentity>.value(value: deviceIdentity),
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
          value: BookingActionRegistry.g3(),
        ),
        RepositoryProvider<MockBookingServer?>.value(
          value: backend.mockServer,
        ),
        RepositoryProvider<StayRepository>.value(value: backend.stay),
        RepositoryProvider<MockStayServer?>.value(value: backend.mockStay),
        RepositoryProvider<ActionAttemptStore>.value(value: actionAttempts),
        RepositoryProvider<NotificationPermission>.value(
          value: notificationPermission,
        ),
        RepositoryProvider<PushMessageSource>.value(value: backend.pushes),
        RepositoryProvider<PushPermissionCoordinator>.value(
          value: pushPermissionCoordinator,
        ),
      ],
      child: OnAirApp(
        favoritesRepository: favorites,
        signOutCoordinator: signOutCoordinator,
        sessionEventSource: sessionEventSource,
        personalDataResetter: CompositePersonalDataResetter([
          bookingsCache.clear,
          paymentAttemptStore.clear,
          arrivalInstructions.clearAll,
          actionAttempts.clearAll,
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
  DeviceIdentity deviceIdentity,
  MockBookingServer? mockServer,
  StayRepository stay,
  MockStayServer? mockStay,
  PushMessageSource pushes,
  NotificationPermission permission,
});

Future<_Backend> _remoteBackend(EnvConfig environment) async {
  // Native Firebase configuration is supplied by the flavor-specific
  // google-services.json / GoogleService-Info.plist. This reuses Android's
  // auto-created [DEFAULT] app and lets Apple initialize from its plist;
  // supplying generated options here duplicates [DEFAULT] in Android release.
  await Firebase.initializeApp();
  // Play Integrity / App Attest protect the WhatsApp OTP send route (R3);
  // debug builds use the debug providers so emulators can run.
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );
  await Supabase.initialize(
    url: environment.supabaseUrl,
    publishableKey: environment.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(localStorage: SecureSessionStorage()),
  );
  final client = Supabase.instance.client;
  Future<dynamic> rpc(String fn, Map<String, dynamic> params) =>
      client.rpc<dynamic>(fn, params: params);
  final deviceIdentity = platformDeviceIdentity();
  final dio = createNodeDio(
    baseUrl: environment.nodeApiBaseUrl,
    tokens: SupabaseTokenSource(client),
    deviceIdentity: deviceIdentity,
    attestation: const FirebaseAppAttestation(),
  );
  final socialCredentials = GoogleAppleCredentialSource(
    serverClientId: environment.googleServerClientId,
    iosClientId: environment.googleIosClientId,
  );
  return (
    config: AppConfigRepository(client),
    auth: SupabaseAuthRepository(
      SupabasePhoneAuthClient(client.auth),
      ProfileRepository(client),
      socialCredentials: socialCredentials,
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
    deviceIdentity: deviceIdentity,
    mockServer: null,
    stay: SupabaseStayRepository(rpc: rpc, node: FallbackClient(dio)),
    mockStay: null,
    pushes: FirebasePushMessageSource(),
    permission: FirebaseNotificationPermission(),
  );
}

/// In-memory backend: no Supabase, Node, or Firebase connection.
_Backend _mockBackend() {
  final rawListings = MockListingsRepository();
  final signals = ControllableNotificationSignalSource();
  // The server reads the raw fixtures; everyone else sees the listings
  // mock with the Home feed's upcoming booking filled from the bookings
  // fixtures (FR-026).
  final server = MockBookingServer(listings: rawListings, signals: signals);
  final stay = MockStayServer(bookings: server);
  final secureStore = InMemorySecureStore();
  final listings = MockHomeFeedWithBookings(
    inner: rawListings,
    server: server,
  );
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
    secureStore: secureStore,
    deviceIdentity: const MemoryDeviceIdentity(),
    mockServer: server,
    stay: stay,
    mockStay: stay,
    pushes: const NoopPushMessageSource(),
    permission: FakeNotificationPermission(),
  );
}

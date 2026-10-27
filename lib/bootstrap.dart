import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/app/app.dart';
import 'package:on_air/app/router/incoming_links.dart';
import 'package:on_air/core/api/generated/rest_client.dart';
import 'package:on_air/core/auth/secure_session_storage.dart';
import 'package:on_air/core/config/app_config_repository.dart';
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
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/features/account_gate/application/device_registration_service.dart';
import 'package:on_air/features/account_gate/application/personal_data_resetter.dart';
import 'package:on_air/features/account_gate/application/sign_out_service.dart';
import 'package:on_air/features/account_gate/data/device_repository.dart';
import 'package:on_air/features/account_gate/presentation/session_listener.dart';
import 'package:on_air/features/auth/data/profile_repository.dart';
import 'package:on_air/features/auth/data/supabase_auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrap(String flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  final environment = EnvConfig.fromEnvironment();
  final uriLinkSource = AppLinksUriSource();
  if (environment.flavor != flavor) {
    throw StateError('Entrypoint flavor does not match FLAVOR');
  }
  final firebaseOptions = switch (flavor) {
    'staging' => staging_firebase.DefaultFirebaseOptions.currentPlatform,
    'production' => production_firebase.DefaultFirebaseOptions.currentPlatform,
    _ => throw StateError('Unsupported Firebase flavor: $flavor'),
  };
  await Firebase.initializeApp(options: firebaseOptions);
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
  await Supabase.initialize(
    url: environment.supabaseUrl,
    publishableKey: environment.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(localStorage: SecureSessionStorage()),
  );
  final client = Supabase.instance.client;
  final dio = createNodeDio(
    baseUrl: environment.nodeApiBaseUrl,
    tokens: SupabaseTokenSource(client),
  );
  final configSource = AppConfigRepository(client);
  final authRepository = SupabaseAuthRepository(
    SupabasePhoneAuthClient(client.auth),
    ProfileRepository(client),
  );
  final pushTokens = FirebasePushTokenSource();
  final devices = DeviceRepository(RestClient(dio).fallback);
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
  final sessionEventSource = SupabaseSessionEventSource(client.auth);
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<EnvConfig>.value(value: environment),
        RepositoryProvider<AppLogger>.value(value: logger),
        RepositoryProvider<SupabaseClient>.value(value: client),
        RepositoryProvider<Dio>.value(value: dio),
        RepositoryProvider<AppConfigSource>.value(value: configSource),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<PushTokenSource>.value(value: pushTokens),
        RepositoryProvider<DeviceTokenRepository>.value(value: devices),
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

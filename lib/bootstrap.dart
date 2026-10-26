import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/app/app.dart';
import 'package:on_air/core/auth/secure_session_storage.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/env/env_config.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/network/dio_factory.dart';
import 'package:on_air/core/network/supabase_token_source.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/features/auth/data/foundation_auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrap(String flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  final environment = EnvConfig.fromEnvironment();
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
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<EnvConfig>.value(value: environment),
        RepositoryProvider<AppLogger>.value(value: logger),
        RepositoryProvider<SupabaseClient>.value(value: client),
        RepositoryProvider<Dio>.value(value: dio),
        RepositoryProvider<AppConfigSource>(
          create: (_) => AppConfigRepository(client),
        ),
        RepositoryProvider<AuthRepository>(
          create: (_) => FoundationAuthRepository(),
        ),
      ],
      child: const OnAirApp(),
    ),
  );
}

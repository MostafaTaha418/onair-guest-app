import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/app.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/home/data/home_feed_cache.dart';
import 'package:on_air/features/listings/data/mock_listings_repository.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/search/domain/last_search_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boots the full [OnAirApp] on the mock backend: in-memory repositories,
/// no Supabase/Firebase connection. Shared by the integration tests that
/// exercise the real shell (the T095 journey, the T105 scroll-perf run).
///
/// On the host, rootBundle never completes under the fake async zone — the
/// fixture files are read directly (the same reason T027 added `loader`).
Future<void> bootMockApp(WidgetTester tester) async {
  CairoTime.initialize();
  SharedPreferences.setMockInitialValues({});
  // Sync IO: async dart:io futures never complete under the fake async
  // zone of a host widget test.
  final directory = Directory.systemTemp.createTempSync('on_air_mock_app');
  addTearDown(() => directory.deleteSync(recursive: true));
  final cache = JsonFileCache(
    directory: directory,
    fileName: 'discovery_cache.json',
    schema: 1,
  );
  final listings =
      TestWidgetsFlutterBinding.instance is AutomatedTestWidgetsFlutterBinding
      ? MockListingsRepository(
          loader: (path) async => File(path).readAsStringSync(),
        )
      : MockListingsRepository();
  final auth = MockAuthRepository();
  addTearDown(auth.dispose);

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppConfigSource>.value(
          value: const MockAppConfigSource(),
        ),
        RepositoryProvider<AuthRepository>.value(value: auth),
        RepositoryProvider<AppLogger>.value(value: AppLogger(sink: (_) {})),
        RepositoryProvider<ListingsRepository>.value(value: listings),
        RepositoryProvider<JsonFileCache>.value(value: cache),
        RepositoryProvider<ReferenceDataCache>.value(
          value: ReferenceDataCache(listings, cache),
        ),
        RepositoryProvider<HomeFeedCache>.value(
          value: HomeFeedCache(cache),
        ),
        RepositoryProvider<LastSearchStore>.value(value: LastSearchStore()),
      ],
      child: const OnAirApp(),
    ),
  );
  await tester.pumpAndSettle();
}

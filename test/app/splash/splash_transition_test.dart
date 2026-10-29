import 'dart:async';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:on_air/app/app.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/home/data/home_feed_cache.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/search/domain/last_search_store.dart';

import '../../helpers/fake_listings_repository.dart';

final class _Auth extends Mock implements AuthRepository {}

final class _Config extends Mock implements AppConfigSource {}

void main() {
  testWidgets('splash waits for session restore but not app config', (
    tester,
  ) async {
    final restored = Completer<GuestAccount?>();
    final configResult = Completer<AppConfig>();
    final auth = _Auth();
    final config = _Config();
    when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
    when(auth.restoreSession).thenAnswer((_) => restored.future);
    when(config.load).thenAnswer((_) => configResult.future);
    final listings = FakeListingsRepository();
    final cache = JsonFileCache(
      directory: Directory.systemTemp.createTempSync('on_air_splash'),
      fileName: 'discovery_cache.json',
      schema: 1,
    );
    addTearDown(() => cache.directory.deleteSync(recursive: true));
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: auth),
          RepositoryProvider<AppConfigSource>.value(value: config),
          RepositoryProvider<AppLogger>.value(value: AppLogger(sink: (_) {})),
          RepositoryProvider<ListingsRepository>.value(
            value: FakeListingsRepository(),
          ),
          RepositoryProvider<JsonFileCache>.value(value: cache),
          RepositoryProvider<ReferenceDataCache>.value(
            value: ReferenceDataCache(listings, cache),
          ),
          RepositoryProvider<LastSearchStore>.value(value: LastSearchStore()),
          RepositoryProvider<HomeFeedCache>.value(value: HomeFeedCache(cache)),
        ],
        child: const OnAirApp(),
      ),
    );
    await tester.pump();
    expect(find.text('OnAir'), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-home')), findsNothing);

    restored.complete(null);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
    configResult.complete(
      const AppConfig(
        minSupportedBuildAndroid: 1,
        minSupportedBuildIos: 1,
        supportPhone: '+201000000000',
        currentTermsVersion: 'v1',
      ),
    );
  });
}

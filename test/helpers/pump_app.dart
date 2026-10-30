import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/share/share_service.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/home/data/home_feed_cache.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import 'fake_listings_repository.dart';
import 'fake_share_service.dart';

extension PumpOnAirApp on WidgetTester {
  Future<void> pumpOnAirApp(
    Widget child, {
    required AuthRepository authRepository,
    required AppConfigSource appConfigRepository,
    AuthCubit? authCubit,
    ThemeMode themeMode = ThemeMode.light,
    ListingsRepository? listingsRepository,
  }) async {
    final listings = listingsRepository ?? FakeListingsRepository();
    final cache = _tempCache();
    final cubit =
        authCubit ??
        AuthCubit(
          authRepository,
          currentTermsVersion:
              (await appConfigRepository.load()).currentTermsVersion,
        );
    await pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: authRepository),
          RepositoryProvider<AppConfigSource>.value(
            value: appConfigRepository,
          ),
          RepositoryProvider<ListingsRepository>.value(value: listings),
          RepositoryProvider<JsonFileCache>.value(value: cache),
          RepositoryProvider<ReferenceDataCache>.value(
            value: ReferenceDataCache(listings, cache),
          ),
          RepositoryProvider<HomeFeedCache>.value(value: HomeFeedCache(cache)),
          RepositoryProvider<ShareService>.value(value: FakeShareService()),
          RepositoryProvider<ShareLinks>.value(
            value: const ShareLinks(linkDomain: 'on-air.website'),
          ),
        ],
        child: BlocProvider<AuthCubit>.value(
          value: cubit,
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: OnAirTheme.light,
            darkTheme: OnAirTheme.dark,
            themeMode: themeMode,
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: child,
            ),
          ),
        ),
      ),
    );
    addTearDown(cubit.close);
  }
}

JsonFileCache _tempCache() {
  final directory = Directory.systemTemp.createTempSync('on_air_test_cache');
  addTearDown(() => directory.deleteSync(recursive: true));
  return JsonFileCache(
    directory: directory,
    fileName: 'discovery_cache.json',
    schema: 1,
  );
}

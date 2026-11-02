import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:on_air/app/splash/splash_screen.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/design_system/components/on_air_bottom_nav.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/home/data/home_feed_cache.dart';
import 'package:on_air/features/home/presentation/home_cubit.dart';
import 'package:on_air/features/home/presentation/home_screen.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_listings_repository.dart';

final class _Connectivity extends Mock implements Connectivity {}

Widget _frame({
  required Widget home,
  required ThemeMode mode,
  required double scale,
  required double width,
  String locale = 'ar',
}) => SizedBox(
  width: width,
  height: 600,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: Locale(locale),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: OnAirTheme.light,
    darkTheme: OnAirTheme.dark,
    themeMode: mode,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: home,
  ),
);

Widget _shell(ThemeMode mode, double scale, double width) {
  final connectivity = _Connectivity();
  when(
    () => connectivity.onConnectivityChanged,
  ).thenAnswer((_) => const Stream.empty());
  when(
    connectivity.checkConnectivity,
  ).thenAnswer((_) async => [ConnectivityResult.wifi]);
  final connectivityCubit = ConnectivityCubit(connectivity: connectivity);
  addTearDown(connectivityCubit.close);

  final listings = FakeListingsRepository()..homeFeedResponses.add(_feed());
  final directory = Directory.systemTemp.createTempSync('on_air_shell_golden');
  addTearDown(() => directory.deleteSync(recursive: true));
  final cache = JsonFileCache(
    directory: directory,
    fileName: 'discovery_cache.json',
    schema: 1,
  );
  final auth = FakeAuthRepository();
  addTearDown(auth.dispose);
  final authCubit = AuthCubit(auth, currentTermsVersion: 'v1');
  addTearDown(authCubit.close);
  final homeCubit = HomeCubit(
    repo: listings,
    cache: HomeFeedCache(cache),
    reference: ReferenceDataCache(listings, cache),
    connectivity: connectivityCubit,
    auth: authCubit,
  );
  addTearDown(homeCubit.close);
  unawaited(homeCubit.start());

  return _frame(
    mode: mode,
    scale: scale,
    width: width,
    home: MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ListingsRepository>.value(value: listings),
        RepositoryProvider<JsonFileCache>.value(value: cache),
        RepositoryProvider<ReferenceDataCache>.value(
          value: ReferenceDataCache(listings, cache),
        ),
        RepositoryProvider<HomeFeedCache>.value(value: HomeFeedCache(cache)),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<HomeCubit>.value(value: homeCubit),
        ],
        child: Scaffold(
          body: const HomeScreen(),
          bottomNavigationBar: OnAirBottomNav(
            currentIndex: 0,
            labels: const ['الرئيسية', 'بحث', 'حجوزاتي', 'المفضلة', 'حسابي'],
            onTap: (_) {},
          ),
        ),
      ),
    ),
  );
}

HomeFeed _feed() => HomeFeed(
  referenceVersion: 'mock-ref-1',
  areas: const FeedSectionReady([
    AreaTile(
      locationId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      name: 'التجمع الخامس',
      listingCount: 42,
      image: null,
    ),
    AreaTile(
      locationId: 'c2b1a0e9-4b3c-4d5e-8f90-a1b2c3d4e5f6',
      name: 'الرحاب',
      listingCount: 18,
      image: null,
    ),
  ]),
  suggested: FeedSectionReady([
    ListingCard(
      id: '550e8400-e29b-41d4-a716-446655440000',
      title: 'شقة 3 غرف بإطلالة',
      propertyType: 'apartment',
      areaName: 'التجمع الخامس',
      cityName: 'القاهرة الجديدة',
      cover: null,
      nightlyPrice: Money(150000),
      ratingAvg: 4.6,
      reviewCount: 12,
      stay: null,
    ),
    ListingCard(
      id: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
      title: 'استوديو مفروش بالكامل',
      propertyType: 'studio',
      areaName: 'الرحاب',
      cityName: 'القاهرة الجديدة',
      cover: null,
      nightlyPrice: Money(90000),
      ratingAvg: null,
      reviewCount: 0,
      stay: null,
    ),
  ]),
  newest: const FeedSectionReady([]),
  upcomingBooking: const FeedSectionReady<UpcomingBookingCard?>(null),
  fetchedAt: DateTime.utc(2026, 10, 28, 10),
);

void main() {
  unawaited(
    goldenTest(
      'splash palette and scaling',
      fileName: 'splash',
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 2000),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          GoldenTestScenario(
            name: 'light',
            child: _frame(
              home: const SplashScreen(),
              mode: ThemeMode.light,
              scale: 1,
              width: 360,
            ),
          ),
          GoldenTestScenario(
            name: 'dark',
            child: _frame(
              home: const SplashScreen(),
              mode: ThemeMode.dark,
              scale: 1,
              width: 360,
            ),
          ),
          GoldenTestScenario(
            name: '1.3x',
            child: _frame(
              home: const SplashScreen(),
              mode: ThemeMode.light,
              scale: 1.3,
              width: 360,
            ),
          ),
          GoldenTestScenario(
            name: '320 wide',
            child: _frame(
              home: const SplashScreen(),
              mode: ThemeMode.light,
              scale: 1,
              width: 320,
            ),
          ),
          GoldenTestScenario(
            name: 'english',
            child: _frame(
              home: const SplashScreen(),
              mode: ThemeMode.light,
              scale: 1,
              width: 360,
              locale: 'en',
            ),
          ),
          GoldenTestScenario(
            name: 'english dark',
            child: _frame(
              home: const SplashScreen(),
              mode: ThemeMode.dark,
              scale: 1,
              width: 360,
              locale: 'en',
            ),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'visitor shell palette and scaling',
      fileName: 'visitor_shell',
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 1400),
      pumpBeforeTest: (tester) async {
        // Let the Home feed fetch land before the frame is captured.
        await tester.pump();
        await tester.pump();
      },
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          GoldenTestScenario(
            name: 'light',
            child: _shell(ThemeMode.light, 1, 360),
          ),
          GoldenTestScenario(
            name: 'dark',
            child: _shell(ThemeMode.dark, 1, 360),
          ),
          GoldenTestScenario(
            name: '1.3x',
            child: _shell(ThemeMode.light, 1.3, 360),
          ),
          GoldenTestScenario(
            name: '320 wide',
            child: _shell(ThemeMode.light, 1, 320),
          ),
        ],
      ),
    ),
  );
}

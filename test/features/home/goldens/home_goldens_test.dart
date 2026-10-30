@Tags(['golden'])
library;

import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/home/data/home_feed_cache.dart';
import 'package:on_air/features/home/presentation/home_cubit.dart';
import 'package:on_air/features/home/presentation/home_screen.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_listings_repository.dart';

Widget _theme(
  ThemeMode mode,
  double scale,
  double width,
  double height,
  Widget child,
) => SizedBox(
  width: width,
  height: height,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: OnAirTheme.light,
    darkTheme: OnAirTheme.dark,
    themeMode: mode,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: true,
      ),
      child: Directionality(textDirection: TextDirection.rtl, child: child!),
    ),
    home: child,
  ),
);

ListingCard _card(String id, String title) => ListingCard(
  id: id,
  title: title,
  propertyType: 'apartment',
  areaName: 'التجمع الخامس',
  cityName: 'القاهرة الجديدة',
  cover: null,
  nightlyPrice: Money(150000),
  ratingAvg: 4.6,
  reviewCount: 12,
  stay: null,
);

HomeFeed _feed({bool withBooking = false}) => HomeFeed(
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
    _card('550e8400-e29b-41d4-a716-446655440000', 'شقة 3 غرف بإطلالة'),
    _card('a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d', 'استوديو مفروش بالكامل'),
  ]),
  newest: FeedSectionReady([
    _card('b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e', 'شقة العيلة في الرحاب'),
    _card('c3d4e5f6-a7b8-4c9d-8e0f-1a2b3c4d5e6f', 'شقة جديدة قرب الحديقة'),
  ]),
  upcomingBooking: withBooking
      ? FeedSectionReady(
          UpcomingBookingCard(
            bookingId: 'b1',
            propertyTitle: 'شقة محجوزة',
            checkIn: DateOnly(2026, 11, 20),
            checkOut: DateOnly(2026, 11, 23),
            status: 'confirmed',
          ),
        )
      : const FeedSectionReady<UpcomingBookingCard?>(null),
  fetchedAt: DateTime.utc(2026, 10, 28, 10),
);

/// Pumps the Home screen with a signed-in or visitor account; the queued
/// feed lands inside the two pump frames, so the capture shows the ready
/// state.
Widget _homeChild({
  required bool signedIn,
  required bool withBooking,
  bool loading = false,
}) {
  final listings = FakeListingsRepository();
  if (loading) {
    // A fetch that never completes holds the loading skeleton on screen.
    listings.homeFeedResponses.add(Completer<HomeFeed>().future);
  } else {
    listings.homeFeedResponses
      ..add(_feed(withBooking: withBooking))
      ..add(_feed(withBooking: withBooking));
  }
  final connectivity = FakeConnectivity();
  final directory = Directory.systemTemp.createTempSync('on_air_home_golden');
  final cache = JsonFileCache(
    directory: directory,
    fileName: 'discovery_cache.json',
    schema: 1,
  );
  final auth = FakeAuthRepository();
  // The account exists before the cubit restores the session, so no extra
  // signed-in refresh races the capture.
  if (signedIn) {
    auth.account = GuestAccount(
      id: 'guest',
      phone: '+201012345678',
      phoneVerified: true,
      fullName: 'زائر تجريبي',
      acceptedTermsVersion: 'v1',
      acceptedTermsAt: DateTime.utc(2026),
    );
  }
  final authCubit = AuthCubit(auth, currentTermsVersion: 'v1');
  unawaited(authCubit.restore());
  final connectivityCubit = connectivity.createCubit();
  final homeCubit = HomeCubit(
    repo: listings,
    cache: HomeFeedCache(cache),
    reference: ReferenceDataCache(listings, cache),
    connectivity: connectivityCubit,
    auth: authCubit,
  );
  unawaited(homeCubit.start());
  return MultiRepositoryProvider(
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
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
        BlocProvider<HomeCubit>.value(value: homeCubit),
      ],
      child: const HomeScreen(),
    ),
  );
}

Future<void> _pumpTwoFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  final modes = [
    ('light_RTL', ThemeMode.light, 1.0),
    ('dark_RTL', ThemeMode.dark, 1.0),
    ('light_RTL_1_3x', ThemeMode.light, 1.3),
    ('dark_RTL_1_3x', ThemeMode.dark, 1.3),
  ];

  for (final (name, mode, scale) in modes) {
    unawaited(
      goldenTest(
        'home ready visitor — $name',
        fileName: 'home_ready_visitor_$name',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 2200),
        pumpBeforeTest: _pumpTwoFrames,
        builder: () => GoldenTestScenario(
          name: name,
          child: _theme(
            mode,
            scale,
            400,
            2100,
            _homeChild(signedIn: false, withBooking: false),
          ),
        ),
      ),
    );
    unawaited(
      goldenTest(
        'home ready signed in — $name',
        fileName: 'home_ready_signed_in_$name',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 2200),
        pumpBeforeTest: _pumpTwoFrames,
        builder: () => GoldenTestScenario(
          name: name,
          child: _theme(
            mode,
            scale,
            400,
            2100,
            _homeChild(signedIn: true, withBooking: true),
          ),
        ),
      ),
    );
    unawaited(
      goldenTest(
        'home loading — $name',
        fileName: 'home_loading_$name',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 1100),
        pumpBeforeTest: _pumpTwoFrames,
        builder: () => GoldenTestScenario(
          name: name,
          child: _theme(
            mode,
            scale,
            400,
            1000,
            _homeChild(signedIn: false, withBooking: false, loading: true),
          ),
        ),
      ),
    );
  }
}

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
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/approved_review.dart';
import 'package:on_air/features/listings/domain/listing_image.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/features/listings/domain/reference_data.dart';
import 'package:on_air/features/property/presentation/property_cubit.dart';
import 'package:on_air/features/property/presentation/property_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_listings_repository.dart';

Widget _theme(
  ThemeMode mode,
  TextDirection direction,
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
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: Directionality(textDirection: direction, child: child!),
    ),
    home: child,
  ),
);

PropertyDetails _details() => PropertyDetails(
  id: 'p1',
  title: 'شقة 3 غرف بإطلالة في التجمع الخامس',
  description: 'وصف طويل للشقة ' * 12,
  propertyType: 'apartment',
  areaName: 'التجمع الخامس',
  cityName: 'القاهرة الجديدة',
  governorateName: 'القاهرة',
  addressText: 'شارع التسعين الشمالي، عمارة 12، الدور 4',
  images: [
    for (var index = 0; index < 3; index++) const ListingImage(variants: []),
  ],
  bedrooms: 3,
  bathrooms: 2,
  maxGuests: 6,
  areaSqm: 160,
  amenities: const [
    Amenity(key: 'wifi', label: 'واي فاي', icon: 'wifi'),
    Amenity(key: 'ac', label: 'تكييف', icon: 'ac'),
    Amenity(key: 'kitchen', label: 'مطبخ', icon: 'kitchen'),
    Amenity(key: 'parking', label: 'موقف سيارات', icon: 'parking'),
  ],
  rules: const StayRules(
    checkInTime: '14:00',
    checkOutTime: '12:00',
    visitorsAllowed: true,
    maxVisitors: 2,
    houseRules: 'ممنوع التدخين داخل الشقة بالكامل، وممنوع الحيوانات الأليفة.',
  ),
  policy: const PolicySummary(
    depositType: DepositType.percent,
    depositPercentBp: 2500,
    depositAmount: null,
    freeCancellationHours: 72,
  ),
  nightlyPrice: Money(150000),
  ratingAvg: 4.6,
  reviewCount: 12,
  latestReviews: [
    ApprovedReview(
      id: 'r1',
      rating: 5,
      comment: 'شقة نظيفة والموقع ممتاز، والاستضافة كانت رائعة.',
      createdOn: DateOnly(2026, 9, 14),
      reviewerShortName: 'أحمد م.',
    ),
    ApprovedReview(
      id: 'r2',
      rating: 4,
      comment: 'مطابقة للصور تماماً.',
      createdOn: DateOnly(2026, 8, 30),
      reviewerShortName: 'منى س.',
    ),
  ],
  termsVersion: 't1',
);

/// The ready details screen; the repository answers inside the two
/// `pumpBeforeTest` frames, so the captured frame shows the ready state.
Widget _readyChild() {
  final listings = FakeListingsRepository()..propertyResponses.add(_details());
  final connectivity = FakeConnectivity();
  final cubit = PropertyCubit(
    repo: listings,
    connectivity: connectivity.createCubit(),
    propertyId: 'p1',
  );
  unawaited(cubit.load());
  final directory = Directory.systemTemp.createTempSync('on_air_golden');
  final cache = JsonFileCache(
    directory: directory,
    fileName: 'discovery_cache.json',
    schema: 1,
  );
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<ListingsRepository>.value(value: listings),
      RepositoryProvider<JsonFileCache>.value(value: cache),
      RepositoryProvider<ReferenceDataCache>.value(
        value: ReferenceDataCache(listings, cache),
      ),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<PropertyCubit>.value(value: cubit),
        BlocProvider<ConnectivityCubit>.value(
          value: connectivity.createCubit(),
        ),
      ],
      child: const PropertyScreen(propertyId: 'p1'),
    ),
  );
}

Widget _loadingChild() {
  final connectivity = FakeConnectivity();
  final listings = FakeListingsRepository();
  final cubit = PropertyCubit(
    repo: listings,
    connectivity: connectivity.createCubit(),
    propertyId: 'p1',
  );
  final directory = Directory.systemTemp.createTempSync('on_air_golden');
  final cache = JsonFileCache(
    directory: directory,
    fileName: 'discovery_cache.json',
    schema: 1,
  );
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<ListingsRepository>.value(value: listings),
      RepositoryProvider<JsonFileCache>.value(value: cache),
      RepositoryProvider<ReferenceDataCache>.value(
        value: ReferenceDataCache(listings, cache),
      ),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<PropertyCubit>.value(value: cubit),
        BlocProvider<ConnectivityCubit>.value(
          value: connectivity.createCubit(),
        ),
      ],
      child: const PropertyScreen(propertyId: 'p1'),
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
    ('light_RTL', ThemeMode.light, TextDirection.rtl, 1.0),
    ('dark_RTL', ThemeMode.dark, TextDirection.rtl, 1.0),
    ('light_RTL_1_3x', ThemeMode.light, TextDirection.rtl, 1.3),
    ('dark_RTL_1_3x', ThemeMode.dark, TextDirection.rtl, 1.3),
  ];

  for (final (name, mode, direction, scale) in modes) {
    unawaited(
      goldenTest(
        'property ready — $name',
        fileName: 'property_ready_$name',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 3400),
        pumpBeforeTest: _pumpTwoFrames,
        builder: () => GoldenTestScenario(
          name: name,
          child: _theme(mode, direction, scale, 400, 3300, _readyChild()),
        ),
      ),
    );
    unawaited(
      goldenTest(
        'property loading — $name',
        fileName: 'property_loading_$name',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 900),
        pumpBeforeTest: _pumpTwoFrames,
        builder: () => GoldenTestScenario(
          name: name,
          child: _theme(mode, direction, scale, 400, 800, _loadingChild()),
        ),
      ),
    );
  }
}

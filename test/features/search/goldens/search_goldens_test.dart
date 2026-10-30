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
import 'package:on_air/features/listings/domain/listing_card.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/reference_data.dart';
import 'package:on_air/features/listings/domain/results_page.dart';
import 'package:on_air/features/search/domain/last_search_store.dart';
import 'package:on_air/features/search/domain/search_criteria.dart';
import 'package:on_air/features/search/presentation/filters_count_cubit.dart';
import 'package:on_air/features/search/presentation/filters_sheet.dart';
import 'package:on_air/features/search/presentation/results_screen.dart';
import 'package:on_air/features/search/presentation/search_cubit.dart';
import 'package:on_air/features/search/presentation/search_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_listings_repository.dart';

/// The shared fakes: one repository per scenario, frozen connectivity.
FakeConnectivity? _connectivity;

void _ensureFakes() {
  SharedPreferences.setMockInitialValues({});
  _connectivity ??= FakeConnectivity();
}

FakeListingsRepository _repositoryWithResults() {
  final repository = FakeListingsRepository();
  repository.referenceDataResponses.add(_reference());
  repository.searchResponses.add(
    ResultsPage(
      items: [
        ListingCard.fromJson(const {
          'id': 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
          'title': 'شقة 3 غرف بإطلالة',
          'property_type': 'apartment',
          'area_name': 'التجمع الخامس',
          'city_name': 'القاهرة الجديدة',
          'nightly_price_minor': 150000,
          'currency': 'EGP',
          'review_count': 12,
          'rating_avg': 4.6,
          'stay': {'nights': 3, 'stay_total_minor': 450000},
        }),
      ],
      nextCursor: null,
      totalCount: 1,
    ),
  );
  return repository;
}

ReferenceData _reference() => ReferenceData(
  version: 'golden-ref-1',
  amenities: const [
    Amenity(key: 'wifi', label: 'واي فاي', icon: null),
    Amenity(key: 'ac', label: 'تكييف', icon: null),
    Amenity(key: 'kitchen', label: 'مطبخ', icon: null),
  ],
  propertyTypes: const [
    PropertyTypeOption(key: 'apartment', label: 'شقة'),
    PropertyTypeOption(key: 'villa', label: 'فيلا'),
  ],
  priceMin: Money(50000),
  priceMax: Money(1500000),
  priceStep: Money(5000),
);

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
    home: Scaffold(body: child),
  ),
);

Widget _searchForm(ThemeMode mode, TextDirection direction, double scale) {
  _ensureFakes();
  final repository = FakeListingsRepository();
  return _theme(
    mode,
    direction,
    scale,
    400,
    720,
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ListingsRepository>.value(value: repository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ConnectivityCubit>.value(
            value: _connectivity!.createCubit(),
          ),
          BlocProvider<SearchCubit>(
            create: (context) => SearchCubit(
              repo: repository,
              lastSearch: LastSearchStore(),
              connectivity: context.read<ConnectivityCubit>(),
              today: () => DateOnly(2026, 11, 1),
            ),
          ),
        ],
        child: const SearchScreen(),
      ),
    ),
  );
}

Widget _results(ThemeMode mode, TextDirection direction, double scale) {
  _ensureFakes();
  final repository = _repositoryWithResults();
  final connectivity = _connectivity!;
  return _theme(
    mode,
    direction,
    scale,
    400,
    760,
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ListingsRepository>.value(value: repository),
        RepositoryProvider<ReferenceDataCache>.value(
          value: ReferenceDataCache(
            repository,
            JsonFileCache(
              directory: Directory.systemTemp.createTempSync('search_golden'),
              fileName: 'x.json',
              schema: 1,
            ),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ConnectivityCubit>.value(
            value: connectivity.createCubit(),
          ),
          BlocProvider<SearchCubit>(
            create: (context) => SearchCubit(
              repo: repository,
              lastSearch: LastSearchStore(),
              connectivity: context.read<ConnectivityCubit>(),
              today: () => DateOnly(2026, 11, 1),
            ),
          ),
        ],
        child: Builder(
          builder: (context) {
            // Present the ready state with chips and the dates hint.
            unawaited(
              context.read<SearchCubit>().search(
                SearchCriteria.fromQuery(
                  {'am': 'wifi', 'g': '2'},
                  today: DateOnly(2026, 11, 1),
                ),
              ),
            );
            return const ResultsScreen();
          },
        ),
      ),
    ),
  );
}

Widget _filtersSheet(ThemeMode mode, TextDirection direction, double scale) {
  _ensureFakes();
  final repository = FakeListingsRepository();
  repository.countResponses.add(137);
  final connectivity = _connectivity!;
  return _theme(
    mode,
    direction,
    scale,
    400,
    760,
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ListingsRepository>.value(value: repository),
        RepositoryProvider<ReferenceDataCache>.value(
          value: ReferenceDataCache(
            repository,
            JsonFileCache(
              directory: Directory.systemTemp.createTempSync('search_golden'),
              fileName: 'x.json',
              schema: 1,
            ),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ConnectivityCubit>.value(
            value: connectivity.createCubit(),
          ),
          BlocProvider<FiltersCountCubit>(
            create: (context) =>
                FiltersCountCubit(
                  repo: repository,
                )..recount(
                  SearchCriteria.fromQuery(
                    {'am': 'wifi', 'bed': '2'},
                    today: DateOnly(2026, 11, 1),
                  ),
                ),
          ),
        ],
        child: Builder(
          builder: (context) => FiltersSheet(
            initial: SearchCriteria.fromQuery(
              {'am': 'wifi', 'bed': '2'},
              today: DateOnly(2026, 11, 1),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  tearDown(() {
    _connectivity?.dispose();
    _connectivity = null;
  });

  final modes = [
    ('light RTL', ThemeMode.light, TextDirection.rtl, 1.0),
    ('dark RTL', ThemeMode.dark, TextDirection.rtl, 1.0),
    ('light LTR', ThemeMode.light, TextDirection.ltr, 1.0),
    ('light RTL 1.3x', ThemeMode.light, TextDirection.rtl, 1.3),
  ];

  for (final (name, mode, direction, scale) in modes) {
    unawaited(
      goldenTest(
        'search screen — $name',
        fileName: 'search_screen_${name.replaceAll(' ', '_')}',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 800),
        builder: () => GoldenTestScenario(
          name: name,
          child: _searchForm(mode, direction, scale),
        ),
      ),
    );
    unawaited(
      goldenTest(
        'results screen — $name',
        fileName: 'search_results_${name.replaceAll(' ', '_')}',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 840),
        builder: () => GoldenTestScenario(
          name: name,
          child: _results(mode, direction, scale),
        ),
      ),
    );
    unawaited(
      goldenTest(
        'filters sheet — $name',
        fileName: 'search_filters_${name.replaceAll(' ', '_')}',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 840),
        builder: () => GoldenTestScenario(
          name: name,
          child: _filtersSheet(mode, direction, scale),
        ),
      ),
    );
  }
}

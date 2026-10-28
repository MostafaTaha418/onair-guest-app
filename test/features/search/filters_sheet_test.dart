import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/design_system/components/counter_stepper.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/reference_data.dart';
import 'package:on_air/features/search/domain/search_criteria.dart';
import 'package:on_air/features/search/presentation/filters_sheet.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_listings_repository.dart';

final AppLocalizations l10n = lookupAppLocalizations(const Locale('ar'));

void main() {
  late FakeListingsRepository listings;
  late ReferenceDataCache referenceCache;

  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    listings = FakeListingsRepository();
    referenceCache = ReferenceDataCache(
      listings,
      JsonFileCache(
        directory: Directory.systemTemp.createTempSync('filters_test'),
        fileName: 'x.json',
        schema: 1,
      ),
    );
  });

  SearchCriteria? popped;

  Future<void> pumpSheet(
    WidgetTester tester, {
    required SearchCriteria initial,
  }) async {
    popped = null;
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ListingsRepository>.value(value: listings),
          RepositoryProvider<ReferenceDataCache>.value(value: referenceCache),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: OnAirTheme.light,
          // Skeletons pulse forever; freeze them so pumpAndSettle works.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () async {
                    popped = await showFiltersSheet(
                      context,
                      initial: initial,
                    );
                  },
                  child: const Text('افتح'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
  }

  testWidgets('the count label updates after the debounce', (tester) async {
    listings.countResponses.add(42);
    await pumpSheet(tester, initial: SearchCriteria.empty);
    // The initial count (queued before opening) resolves.
    await tester.pumpAndSettle();
    expect(find.text(l10n.searchShowResults(42)), findsOneWidget);

    listings.countResponses.add(7);
    await tester.tap(find.byTooltip(l10n.countIncrease).first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text(l10n.searchShowResults(7)), findsOneWidget);
  });

  testWidgets('«مسح الكل» resets every filter', (tester) async {
    listings.countResponses.add(1);
    await pumpSheet(
      tester,
      initial: SearchCriteria.fromQuery(
        {'am': 'wifi', 'bed': '2', 'pmin': '10000'},
        today: DateOnly(2026, 11, 1),
      ),
    );
    await tester.pumpAndSettle();

    listings.countResponses.add(1);
    await tester.tap(find.text(l10n.searchClearAll));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.searchShowResults(1)));
    await tester.pumpAndSettle();
    expect(popped, isNotNull);
    expect(popped!.amenityKeys, isEmpty);
    expect(popped!.minBedrooms, isNull);
    expect(popped!.priceMin, isNull);
  });

  testWidgets('confirming returns the edited criteria', (tester) async {
    listings.countResponses.add(3);
    listings.referenceDataResponses.add(_reference());
    await pumpSheet(tester, initial: SearchCriteria.empty);
    await tester.pumpAndSettle();

    // Pick the first amenity chip.
    final chips = find.byType(FilterChip);
    expect(chips, findsWidgets);
    await tester.tap(chips.first);
    await tester.pump();

    listings.countResponses.add(3);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.searchShowResults(3)));
    await tester.pumpAndSettle();

    expect(popped, isNotNull);
    expect(popped!.amenityKeys, isNotEmpty);
  });

  testWidgets('a reference-data failure shows retry inside the sheet', (
    tester,
  ) async {
    listings.referenceDataResponses.add(
      const AppFailure(
        ApiError(code: ErrorCode.internal, messageKey: 'errorUnexpected'),
      ),
    );
    await pumpSheet(tester, initial: SearchCriteria.empty);
    await tester.pumpAndSettle();

    expect(find.text(l10n.retry), findsOneWidget);

    // A retry that succeeds recovers the sheet.
    listings.referenceDataResponses.add(_reference());
    await tester.tap(find.text(l10n.retry));
    await tester.pumpAndSettle();
    expect(find.byType(CounterStepper), findsNWidgets(2));
  });
}

ReferenceData _reference() => ReferenceData(
  version: 'v1',
  amenities: const [
    Amenity(key: 'wifi', label: 'واي فاي', icon: null),
    Amenity(key: 'ac', label: 'تكييف', icon: null),
  ],
  propertyTypes: const [
    PropertyTypeOption(key: 'apartment', label: 'شقة'),
    PropertyTypeOption(key: 'villa', label: 'فيلا'),
  ],
  priceMin: Money(50000),
  priceMax: Money(1500000),
  priceStep: Money(5000),
);

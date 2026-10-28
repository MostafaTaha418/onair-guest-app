import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/range_calendar.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/location_suggestion.dart';
import 'package:on_air/features/search/domain/last_search_store.dart';
import 'package:on_air/features/search/presentation/location_suggest_cubit.dart';
import 'package:on_air/features/search/presentation/search_cubit.dart';
import 'package:on_air/features/search/presentation/search_screen.dart';
import 'package:on_air/features/search/presentation/widgets/date_range_sheet.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_connectivity.dart';
import '../../helpers/fake_listings_repository.dart';

void main() {
  late FakeConnectivity connectivity;
  late FakeListingsRepository listings;

  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    connectivity = FakeConnectivity();
    listings = FakeListingsRepository();
  });

  tearDown(() {
    connectivity.dispose();
  });

  final l10n = lookupAppLocalizations(const Locale('ar'));
  DateOnly today() => DateOnly(2026, 11, 1);

  Future<void> pumpScreen(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.search,
      routes: [
        GoRoute(
          path: AppRoutes.search,
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider<SearchCubit>(
                create: (_) => SearchCubit(
                  repo: listings,
                  lastSearch: LastSearchStore(),
                  connectivity: connectivity.createCubit(),
                  today: today,
                ),
              ),
              BlocProvider<LocationSuggestCubit>(
                create: (_) => LocationSuggestCubit(repo: listings),
              ),
            ],
            child: const SearchScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.searchResults,
          builder: (_, _) => const Text('نتايج البحث'),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ListingsRepository>.value(value: listings),
        ],
        child: BlocProvider<ConnectivityCubit>.value(
          value: connectivity.createCubit(),
          child: MaterialApp.router(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: OnAirTheme.light,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('with no input, «ابحث» is enabled and opens the results route', (
    tester,
  ) async {
    await pumpScreen(tester);

    final button = tester.widget<OnAirPrimaryButton>(
      find.widgetWithText(OnAirPrimaryButton, l10n.searchAction),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.text(l10n.searchAction));
    await tester.pumpAndSettle();
    expect(find.text('نتايج البحث'), findsOneWidget);
  });

  testWidgets('typing shows suggestions; tapping one fills the field', (
    tester,
  ) async {
    listings.locationResponses.add([
      const LocationSuggestion(
        id: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        level: LocationLevel.area,
        name: 'التجمع الخامس',
        parentLabel: 'القاهرة الجديدة',
        listingCount: 42,
      ),
    ]);
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'التج');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('التجمع الخامس'), findsOneWidget);
    expect(find.text('القاهرة الجديدة'), findsOneWidget);
    expect(find.textContaining('42'), findsOneWidget);

    await tester.tap(find.text('التجمع الخامس'));
    await tester.pump();
    expect(
      find.widgetWithText(TextField, 'التجمع الخامس'),
      findsOneWidget,
    );
  });

  testWidgets('the dates row opens the date sheet', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(l10n.searchDatesHint));
    await tester.pumpAndSettle();
    expect(find.byType(RangeCalendar), findsOneWidget);
  });

  testWidgets('the date sheet blocks past days until a valid range', (
    tester,
  ) async {
    StayRange? popped;
    // A narrow window keeps the calendar cells phone-sized so every day is
    // inside the sheet's viewport.
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: OnAirTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (sheetContext) => Center(
              child: TextButton(
                onPressed: () async {
                  popped = await showModalBottomSheet<StayRange>(
                    context: sheetContext,
                    builder: (_) => DateRangeSheet(
                      today: DateOnly(2026, 11, 10),
                    ),
                  );
                },
                child: const Text('افتح'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    OnAirPrimaryButton confirmButton() => tester.widget<OnAirPrimaryButton>(
      find.widgetWithText(OnAirPrimaryButton, l10n.calendarConfirm),
    );
    expect(confirmButton().onPressed, isNull, reason: 'nothing picked yet');

    // A past day (today is 2026-11-10) never becomes the check-in.
    await tester.tap(find.text('5'));
    await tester.pump();
    expect(confirmButton().onPressed, isNull);

    await tester.tap(find.text('20'));
    await tester.pump();
    await tester.tap(find.text('23'));
    await tester.pump();
    expect(confirmButton().onPressed, isNotNull);

    await tester.tap(find.text(l10n.calendarConfirm));
    await tester.pumpAndSettle();
    expect(popped, isNotNull);
    expect(popped!.nights, 3);
  });

  testWidgets('offline disables «ابحث»', (tester) async {
    await pumpScreen(tester);
    connectivity.goOffline();
    await tester.pump(const Duration(milliseconds: 100));

    final button = tester.widget<OnAirPrimaryButton>(
      find.widgetWithText(OnAirPrimaryButton, l10n.searchAction),
    );
    expect(button.onPressed, isNull);
    expect(find.text(l10n.offline), findsOneWidget);
  });
}

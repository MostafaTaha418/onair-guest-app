import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/features/property/domain/resume_intent.dart';
import 'package:on_air/features/property/presentation/property_cubit.dart';
import 'package:on_air/features/property/presentation/property_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_connectivity.dart';
import '../../helpers/fake_listings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CairoTime.initialize();

  late FakeListingsRepository listings;
  late FakeConnectivity connectivity;
  late FakeAuthRepository auth;
  late Directory directory;
  late JsonFileCache cache;
  String? lastPropertyLocation;
  Map<String, String>? loginQuery;
  Map<String, String>? bookingQuery;
  Map<String, String>? supportQuery;

  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    listings = FakeListingsRepository();
    connectivity = FakeConnectivity();
    auth = FakeAuthRepository();
    directory = Directory.systemTemp.createTempSync('on_air_resume_test');
    cache = JsonFileCache(
      directory: directory,
      fileName: 'discovery_cache.json',
      schema: 1,
    );
    lastPropertyLocation = null;
    loginQuery = null;
    bookingQuery = null;
    supportQuery = null;
  });

  tearDown(() {
    connectivity.dispose();
    unawaited(auth.dispose());
    directory.deleteSync(recursive: true);
  });

  final l10n = lookupAppLocalizations(const Locale('ar'));

  PropertyDetails details({String termsVersion = 't1'}) => PropertyDetails(
    id: 'p1',
    title: 'شقة التجمع الخامس',
    description: 'وصف تجريبي',
    propertyType: 'apartment',
    areaName: 'التجمع الخامس',
    cityName: 'القاهرة الجديدة',
    governorateName: 'القاهرة',
    addressText: null,
    images: const [],
    bedrooms: 3,
    bathrooms: 2,
    maxGuests: 6,
    areaSqm: null,
    amenities: const [],
    rules: const StayRules(
      checkInTime: '14:00',
      checkOutTime: '12:00',
      visitorsAllowed: false,
      maxVisitors: null,
      houseRules: null,
    ),
    policy: const PolicySummary(
      depositType: DepositType.full,
      depositPercentBp: null,
      depositAmount: null,
      freeCancellationHours: 24,
    ),
    nightlyPrice: Money(150000),
    ratingAvg: null,
    reviewCount: 0,
    latestReviews: const [],
    termsVersion: termsVersion,
  );

  Future<void> pumpResume(
    WidgetTester tester, {
    required bool signedIn,
    required Map<String, String> query,
    String termsVersion = 't1',
    int detailLoads = 3,
    AppFailure? failure,
  }) async {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    if (failure != null) {
      listings.propertyResponses.add(failure);
    }
    for (var index = 0; index < detailLoads; index++) {
      listings.propertyResponses.add(details(termsVersion: termsVersion));
    }
    if (signedIn) {
      auth.account = GuestAccount(
        id: 'guest',
        phone: '+201012345678',
        phoneVerified: true,
        fullName: 'زائر',
        acceptedTermsVersion: 'v1',
        acceptedTermsAt: DateTime.utc(2026),
      );
    }
    final authCubit = AuthCubit(auth, currentTermsVersion: 'v1');
    unawaited(authCubit.restore());
    addTearDown(authCubit.close);
    final router = GoRouter(
      initialLocation: Uri(
        path: '/property/p1',
        queryParameters: query,
      ).toString(),
      routes: [
        GoRoute(
          path: '/property/:id',
          builder: (context, state) {
            final q = state.uri.queryParameters;
            lastPropertyLocation = state.uri.toString();
            return BlocProvider<PropertyCubit>(
              create: (context) {
                final cubit = PropertyCubit(
                  repo: listings,
                  connectivity: context.read<ConnectivityCubit>(),
                  propertyId: state.pathParameters['id']!,
                  initialStay: StayRange.tryCreate(
                    DateOnly.tryParse(q['checkIn']),
                    DateOnly.tryParse(q['checkOut']),
                    DateOnly(2026, 11, 1),
                  ),
                  initialGuests: int.tryParse(q['guests'] ?? ''),
                  pendingResume: ResumeIntent.fromQuery(
                    q,
                    today: DateOnly(2026, 11, 1),
                  ),
                );
                unawaited(cubit.load());
                return cubit;
              },
              child: PropertyScreen(propertyId: state.pathParameters['id']!),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.bookingEntryPattern,
          builder: (_, state) {
            bookingQuery = state.uri.queryParameters;
            return const Text('booking-stub');
          },
        ),
        GoRoute(
          path: AppRoutes.supportNew,
          builder: (_, state) {
            supportQuery = state.uri.queryParameters;
            return const Text('support-stub');
          },
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, state) {
            loginQuery = state.uri.queryParameters;
            return const Text('login-stub');
          },
        ),
      ],
    );
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ListingsRepository>.value(value: listings),
          RepositoryProvider<JsonFileCache>.value(value: cache),
          RepositoryProvider<ReferenceDataCache>.value(
            value: ReferenceDataCache(listings, cache),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<ConnectivityCubit>.value(
              value: connectivity.createCubit(),
            ),
          ],
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
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('a visitor «احجز الآن» pushes login with from and cancelTo', (
    tester,
  ) async {
    await pumpResume(
      tester,
      signedIn: false,
      query: {'checkIn': '2026-11-20', 'checkOut': '2026-11-23', 'guests': '2'},
    );

    await tester.tap(find.text(l10n.bookNow));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('login-stub'), findsOneWidget);
    final from = loginQuery!['from']!;
    expect(from, contains('/property/p1'));
    expect(from, contains('checkIn=2026-11-20'));
    expect(from, contains('checkOut=2026-11-23'));
    expect(from, contains('guests=2'));
    expect(from, contains('resume=book'));
    expect(from, contains('terms=t1'));

    final cancelTo = loginQuery!['cancelTo']!;
    expect(cancelTo, contains('/property/p1'));
    expect(cancelTo, contains('checkIn=2026-11-20'));
    expect(cancelTo, isNot(contains('resume')));
    expect(cancelTo, isNot(contains('terms')));
  });

  testWidgets(
    'resume=book with matching terms continues to the booking entry',
    (tester) async {
      await pumpResume(
        tester,
        signedIn: true,
        query: {
          'checkIn': '2026-11-20',
          'checkOut': '2026-11-23',
          'guests': '2',
          'resume': 'book',
          'terms': 't1',
        },
      );

      expect(find.text('booking-stub'), findsOneWidget);
      expect(bookingQuery!['terms'], 't1');
      expect(bookingQuery!['checkIn'], '2026-11-20');
      expect(bookingQuery!['checkOut'], '2026-11-23');
      expect(bookingQuery!['guests'], '2');
      expect(
        lastPropertyLocation,
        isNot(contains('resume')),
        reason: 'Back must never re-trigger the consumed intent',
      );
      expect(lastPropertyLocation, isNot(contains('terms')));
      expect(lastPropertyLocation, contains('checkIn=2026-11-20'));
    },
  );

  testWidgets('changed terms stop the resume and show the notice', (
    tester,
  ) async {
    await pumpResume(
      tester,
      signedIn: true,
      termsVersion: 't2',
      query: {
        'checkIn': '2026-11-20',
        'checkOut': '2026-11-23',
        'resume': 'book',
        'terms': 't1',
      },
    );

    expect(find.text('booking-stub'), findsNothing);
    expect(find.text(l10n.propertyTermsUpdated), findsOneWidget);
    expect(lastPropertyLocation, isNot(contains('resume')));
  });

  testWidgets('resume=contact pushes support with the property id', (
    tester,
  ) async {
    await pumpResume(
      tester,
      signedIn: true,
      query: {'resume': 'contact'},
    );

    expect(find.text('support-stub'), findsOneWidget);
    expect(supportQuery!['property'], 'p1');
  });

  testWidgets('NOT_FOUND ignores the carried intent', (tester) async {
    await pumpResume(
      tester,
      signedIn: true,
      query: {'resume': 'book', 'terms': 't1'},
      detailLoads: 0,
      failure: AppFailure(ErrorMapper.fromCode('NOT_FOUND')),
    );

    expect(find.text(l10n.notAvailable), findsOneWidget);
    expect(find.text('booking-stub'), findsNothing);
    expect(find.text('support-stub'), findsNothing);
    expect(find.text('login-stub'), findsNothing);
  });
}

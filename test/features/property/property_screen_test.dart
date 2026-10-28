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
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/approved_review.dart';
import 'package:on_air/features/listings/domain/listing_image.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/features/listings/domain/reference_data.dart';
import 'package:on_air/features/property/presentation/property_cubit.dart';
import 'package:on_air/features/property/presentation/property_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_connectivity.dart';
import '../../helpers/fake_listings_repository.dart';

void main() {
  late FakeListingsRepository listings;
  late FakeConnectivity connectivity;
  late FakeAuthRepository auth;
  Map<String, String>? bookingQuery;

  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    listings = FakeListingsRepository();
    connectivity = FakeConnectivity();
    auth = FakeAuthRepository();
    bookingQuery = null;
  });

  tearDown(() {
    connectivity.dispose();
    unawaited(auth.dispose());
  });

  final l10n = lookupAppLocalizations(const Locale('ar'));

  PropertyDetails details({String? addressText = 'شارع 90، عمارة 12'}) =>
      PropertyDetails(
        id: 'p1',
        title: 'شقة 3 غرف بإطلالة',
        description: 'وصف طويل ' * 12,
        propertyType: 'apartment',
        areaName: 'التجمع الخامس',
        cityName: 'القاهرة الجديدة',
        governorateName: 'القاهرة',
        addressText: addressText,
        images: const [
          ListingImage(variants: []),
          ListingImage(variants: []),
        ],
        bedrooms: 3,
        bathrooms: 2,
        maxGuests: 6,
        areaSqm: 160,
        amenities: const [
          Amenity(key: 'wifi', label: 'واي فاي', icon: 'wifi'),
          Amenity(key: 'ac', label: 'تكييف', icon: 'ac'),
        ],
        rules: const StayRules(
          checkInTime: '14:00',
          checkOutTime: '12:00',
          visitorsAllowed: true,
          maxVisitors: 2,
          houseRules: 'ممنوع التدخين',
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
            comment: 'ممتازة',
            createdOn: DateOnly(2026, 9, 14),
            reviewerShortName: 'أحمد م.',
          ),
        ],
        termsVersion: 't1',
      );

  Future<void> pumpProperty(
    WidgetTester tester, {
    required bool signedIn,
    Map<String, String> query = const {},
    double height = 3000,
  }) async {
    tester.view.physicalSize = Size(400, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: Uri(
        path: '/property/p1',
        queryParameters: query.isEmpty ? null : query,
      ).toString(),
      routes: [
        GoRoute(
          path: '/property/:id',
          builder: (context, state) {
            final q = state.uri.queryParameters;
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
          builder: (_, _) => const Text('support-stub'),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => const Text('login-stub'),
        ),
      ],
    );
    // The account must exist before the cubit's session restore reads it.
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
    final cacheDirectory = Directory.systemTemp.createTempSync(
      'on_air_property_test',
    );
    addTearDown(() => cacheDirectory.deleteSync(recursive: true));
    final cache = JsonFileCache(
      directory: cacheDirectory,
      fileName: 'discovery_cache.json',
      schema: 1,
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
    // Let the auth restore and the property load settle; the loading
    // skeletons animate, so pumpAndSettle never finishes.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('the ready state shows every section title', (tester) async {
    listings.propertyResponses.add(details());
    await pumpProperty(tester, signedIn: false);

    expect(find.text(l10n.propertyDescription), findsOneWidget);
    expect(find.text(l10n.propertyAmenities), findsOneWidget);
    expect(find.text(l10n.propertyLocation), findsOneWidget);
    expect(find.text(l10n.propertyRules), findsOneWidget);
    expect(find.text(l10n.propertyPolicy), findsOneWidget);
    expect(find.text(l10n.propertyAvailability), findsOneWidget);
    expect(find.text(l10n.propertyReviews), findsOneWidget);
  });

  testWidgets('the price is the single money row (AC-010)', (tester) async {
    listings.propertyResponses.add(details());
    await pumpProperty(tester, signedIn: false);

    expect(find.textContaining('EGP'), findsOneWidget);
  });

  testWidgets('the address row is hidden when addressText is null', (
    tester,
  ) async {
    listings.propertyResponses.add(details(addressText: null));
    await pumpProperty(tester, signedIn: false);

    expect(find.text(l10n.propertyLocation), findsOneWidget);
    expect(find.text('شارع 90، عمارة 12'), findsNothing);
  });

  testWidgets('no owner contact anywhere (AC-047)', (tester) async {
    listings.propertyResponses.add(details());
    await pumpProperty(tester, signedIn: false);

    expect(find.textContaining('المالك'), findsNothing);
    expect(find.textContaining(RegExp(r'\+?\d[\d\s-]{8,}')), findsNothing);
  });

  testWidgets('signed-in «احجز الآن» pushes the booking entry with terms', (
    tester,
  ) async {
    listings.propertyResponses.add(details());
    await pumpProperty(
      tester,
      signedIn: true,
      query: {
        'checkIn': '2026-11-20',
        'checkOut': '2026-11-23',
        'guests': '4',
      },
    );

    await tester.tap(find.text(l10n.bookNow));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('booking-stub'), findsOneWidget);
    expect(bookingQuery, isNotNull);
    expect(bookingQuery!['terms'], 't1');
    expect(bookingQuery!['checkIn'], '2026-11-20');
    expect(bookingQuery!['checkOut'], '2026-11-23');
    expect(bookingQuery!['guests'], '4');
  });

  testWidgets('«احجز الآن» is disabled offline', (tester) async {
    listings.propertyResponses.add(details());
    await pumpProperty(tester, signedIn: true);
    connectivity.goOffline();
    await tester.pump(const Duration(milliseconds: 100));

    final button = tester.widget<OnAirPrimaryButton>(
      find.widgetWithText(OnAirPrimaryButton, l10n.bookNow),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('NOT_FOUND shows the not-available content', (tester) async {
    listings.propertyResponses.add(
      AppFailure(ErrorMapper.fromCode('NOT_FOUND')),
    );
    await pumpProperty(tester, signedIn: false);

    expect(find.text(l10n.notAvailable), findsOneWidget);
  });

  testWidgets('picking a valid range updates the bottom-bar caption', (
    tester,
  ) async {
    listings.propertyResponses.add(details());
    await pumpProperty(tester, signedIn: false);

    // CairoTime.today() is the real clock; the calendar shows the current
    // month (October 2026), so pick from its selectable tail.
    await tester.tap(find.text('29'));
    await tester.pump();
    await tester.tap(find.text('30'));
    await tester.pump();
    await tester.tap(find.text(l10n.calendarConfirm));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('29 أكتوبر'), findsOneWidget);
  });

  testWidgets('an invalid range shows calendarRangeInvalid', (tester) async {
    listings.propertyResponses.add(details());
    listings.unavailableNightsResponses.add({DateOnly(2026, 10, 30)});
    await pumpProperty(tester, signedIn: false);

    await tester.tap(find.text('29'));
    await tester.pump();
    await tester.tap(find.text('31'));
    await tester.pump();

    expect(find.text(l10n.calendarRangeInvalid), findsOneWidget);
  });

  testWidgets('a visitor «احجز الآن» goes to sign-in', (tester) async {
    listings.propertyResponses.add(details());
    await pumpProperty(tester, signedIn: false);

    await tester.tap(find.text(l10n.bookNow));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('login-stub'), findsOneWidget);
  });

  testWidgets('«تواصل مع OnAir» signed in pushes support', (tester) async {
    listings.propertyResponses.add(details());
    await pumpProperty(tester, signedIn: true);

    await tester.tap(find.text(l10n.propertyContactOnAir));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('support-stub'), findsOneWidget);
  });
}

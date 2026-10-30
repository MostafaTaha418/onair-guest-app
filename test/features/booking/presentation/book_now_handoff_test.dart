import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/design_system/components/counter_stepper.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/booking/presentation/booking_flow_cubit.dart';
import 'package:on_air/features/booking/presentation/dates_screen.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/features/property/presentation/property_cubit.dart';
import 'package:on_air/features/property/presentation/property_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_listings_repository.dart';
import '../../../helpers/pump_app.dart';

PropertyDetails _property() => PropertyDetails(
  id: '00000000-0000-4000-8000-00000000001f',
  title: 'شقة 3 غرف للتجربة',
  description: 'وصف',
  propertyType: 'apartment',
  areaName: 'المعادي',
  cityName: 'القاهرة',
  governorateName: 'القاهرة',
  addressText: 'شارع 9',
  images: const [],
  bedrooms: 3,
  bathrooms: 2,
  maxGuests: 6,
  areaSqm: 120,
  amenities: const [],
  rules: const StayRules(
    checkInTime: '14:00',
    checkOutTime: '12:00',
    visitorsAllowed: false,
    maxVisitors: null,
    houseRules: null,
  ),
  policy: const PolicySummary(
    depositType: DepositType.percent,
    depositPercentBp: 2500,
    depositAmount: null,
    freeCancellationHours: 72,
  ),
  nightlyPrice: Money(150000),
  ratingAvg: null,
  reviewCount: 0,
  latestReviews: const [],
  termsVersion: 'mock-terms-1',
);

void main() {
  const property1f = '00000000-0000-4000-8000-00000000001f';

  late FakeBookingBackend backend;
  late FakeConnectivity connectivity;
  late FakeListingsRepository listings;
  late FakeAuthRepository auth;
  late AppLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('ar');
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    CairoTime.initialize();
  });

  setUp(() {
    connectivity = FakeConnectivity();
    listings = FakeListingsRepository();
    auth = FakeAuthRepository();
    backend = FakeBookingBackend();
  });

  tearDown(() {
    backend.dispose();
    connectivity.dispose();
  });

  Future<void> pumpHandoff(
    WidgetTester tester, {
    required Map<String, String> query,
  }) async {
    tester.view.physicalSize = const Size(400, 4200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    listings.propertyResponses.add(_property());
    final router = GoRouter(
      initialLocation: Uri(
        path: AppRoutes.property(property1f),
        queryParameters: query,
      ).toString(),
      routes: [
        GoRoute(
          path: AppRoutes.propertyPattern,
          builder: (context, state) {
            final q = state.uri.queryParameters;
            return BlocProvider<PropertyCubit>(
              create: (context) {
                final cubit = PropertyCubit(
                  repo: listings,
                  connectivity: context.read<ConnectivityCubit>(),
                  propertyId: property1f,
                  initialStay: StayRange.tryCreate(
                    DateOnly.tryParse(q['checkIn']),
                    DateOnly.tryParse(q['checkOut']),
                    CairoTime.today(),
                  ),
                  initialGuests: int.tryParse(q['guests'] ?? ''),
                );
                unawaited(cubit.load());
                return cubit;
              },
              child: const PropertyScreen(propertyId: property1f),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.bookingEntryPattern,
          builder: (context, state) => BlocProvider<BookingFlowCubit>(
            create: (context) {
              final q = state.uri.queryParameters;
              final cubit = BookingFlowCubit(
                listings: listings,
                flow: backend.server,
                connectivity: context.read<ConnectivityCubit>(),
                propertyId: property1f,
                termsHash: q['terms'] ?? '',
                initialStay: StayRange.tryCreate(
                  DateOnly.tryParse(q['checkIn']),
                  DateOnly.tryParse(q['checkOut']),
                  CairoTime.today(),
                ),
                initialGuests: int.tryParse(q['guests'] ?? ''),
              );
              unawaited(cubit.load());
              return cubit;
            },
            child: const DatesScreen(propertyId: property1f),
          ),
        ),
      ],
    );
    // The account must exist before the cubit's restore reads it.
    auth.account = GuestAccount(
      id: 'guest',
      phone: '+201012345678',
      phoneVerified: true,
      fullName: 'زائر',
      acceptedTermsVersion: 'mock-terms-1',
      acceptedTermsAt: DateTime.utc(2026),
    );
    final authCubit = AuthCubit(auth, currentTermsVersion: 'mock-terms-1');
    unawaited(authCubit.restore());
    addTearDown(authCubit.close);
    await tester.pumpOnAirApp(
      const SizedBox.shrink(),
      routerConfig: router,
      authRepository: auth,
      authCubit: authCubit,
      appConfigRepository: FakeAppConfigRepository(
        const AppConfig(
          minSupportedBuildAndroid: 1,
          minSupportedBuildIos: 1,
          supportPhone: '+201000000000',
          currentTermsVersion: 'mock-terms-1',
        ),
      ),
      bookingBackend: backend,
      listingsRepository: listings,
      connectivityCubit: connectivity.createCubit(),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('book now hands the stay, guests, and terms to the date step', (
    tester,
  ) async {
    final checkIn = CairoTime.today().addDays(20);
    final checkOut = CairoTime.today().addDays(23);
    await pumpHandoff(
      tester,
      query: {
        'checkIn': checkIn.toString(),
        'checkOut': checkOut.toString(),
        'guests': '2',
      },
    );

    await tester.tap(find.text(l10n.bookNow));
    await tester.pumpAndSettle();

    expect(find.byType(DatesScreen), findsOneWidget);
    expect(find.text(l10n.bookingNightsCount('3')), findsOneWidget);
    // The stepper shows the carried guest count.
    expect(
      find.descendant(
        of: find.byType(CounterStepper),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
  });
}

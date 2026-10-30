import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/features/property/presentation/property_cubit.dart';

import '../../helpers/fake_connectivity.dart';
import '../../helpers/fake_listings_repository.dart';

PropertyDetails _details({String termsVersion = 't1'}) => PropertyDetails(
  id: 'p1',
  title: 'شقة التجمع الخامس',
  description: 'وصف تجريبي',
  propertyType: 'apartment',
  areaName: 'التجمع الخامس',
  cityName: 'القاهرة الجديدة',
  governorateName: 'القاهرة',
  addressText: 'شارع 90',
  images: const [],
  bedrooms: 3,
  bathrooms: 2,
  maxGuests: 6,
  areaSqm: null,
  amenities: const [],
  rules: const StayRules(
    checkInTime: '14:00',
    checkOutTime: '12:00',
    visitorsAllowed: true,
    maxVisitors: 2,
    houseRules: null,
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
  latestReviews: const [],
  termsVersion: termsVersion,
);

StayRange _range() => StayRange(DateOnly(2026, 11, 20), DateOnly(2026, 11, 23));

void main() {
  late FakeListingsRepository listings;
  late FakeConnectivity connectivity;

  setUp(() {
    listings = FakeListingsRepository();
    connectivity = FakeConnectivity();
  });

  tearDown(() {
    connectivity.dispose();
  });

  ConnectivityCubit onlineCubit() => connectivity.createCubit();

  blocTest<PropertyCubit, PropertyState>(
    'load emits loading then ready',
    build: () {
      listings.propertyResponses.add(_details());
      return PropertyCubit(
        repo: listings,
        connectivity: onlineCubit(),
        propertyId: 'p1',
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => [isA<PropertyLoading>(), isA<PropertyReady>()],
  );

  blocTest<PropertyCubit, PropertyState>(
    'NOT_FOUND becomes the neutral not-available state',
    build: () {
      listings.propertyResponses.add(
        AppFailure(ErrorMapper.fromCode('NOT_FOUND')),
      );
      return PropertyCubit(
        repo: listings,
        connectivity: onlineCubit(),
        propertyId: 'p1',
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => [isA<PropertyLoading>(), isA<PropertyNotAvailable>()],
  );

  blocTest<PropertyCubit, PropertyState>(
    'a network error while offline becomes the offline state',
    build: () {
      listings.propertyResponses.add(AppFailure(ErrorMapper.noResponse()));
      return PropertyCubit(
        repo: listings,
        connectivity: onlineCubit(),
        propertyId: 'p1',
      );
    },
    act: (cubit) async {
      connectivity.goOffline();
      await Future<void>.delayed(Duration.zero);
      await cubit.load();
    },
    expect: () => [isA<PropertyLoading>(), isA<PropertyOffline>()],
  );

  blocTest<PropertyCubit, PropertyState>(
    'other errors become the failed state',
    build: () {
      listings.propertyResponses.add(
        AppFailure(ErrorMapper.fromCode('INTERNAL')),
      );
      return PropertyCubit(
        repo: listings,
        connectivity: onlineCubit(),
        propertyId: 'p1',
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => [isA<PropertyLoading>(), isA<PropertyFailed>()],
  );

  blocTest<PropertyCubit, PropertyState>(
    'retry calls the repository again',
    build: () {
      listings.propertyResponses
        ..add(AppFailure(ErrorMapper.fromCode('INTERNAL')))
        ..add(_details());
      return PropertyCubit(
        repo: listings,
        connectivity: onlineCubit(),
        propertyId: 'p1',
      );
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.retry();
    },
    expect: () => [
      isA<PropertyLoading>(),
      isA<PropertyFailed>(),
      isA<PropertyLoading>(),
      isA<PropertyReady>(),
    ],
    verify: (_) => expect(
      listings.calls.where((call) => call.startsWith('property(')),
      hasLength(2),
    ),
  );

  test('setStay updates the stay in the ready state', () async {
    listings.propertyResponses.add(_details());
    final cubit = PropertyCubit(
      repo: listings,
      connectivity: onlineCubit(),
      propertyId: 'p1',
    );
    addTearDown(cubit.close);
    await cubit.load();
    final range = _range();

    cubit.setStay(range);

    final ready = cubit.state as PropertyReady;
    expect(ready.stay, range);
  });

  test(
    'an initial stay and guests passed to the constructor are kept',
    () async {
      listings.propertyResponses.add(_details());
      final range = _range();
      final cubit = PropertyCubit(
        repo: listings,
        connectivity: onlineCubit(),
        propertyId: 'p1',
        initialStay: range,
        initialGuests: 4,
      );
      addTearDown(cubit.close);
      await cubit.load();

      final ready = cubit.state as PropertyReady;
      expect(ready.stay, range);
      expect(ready.guests, 4);
      expect(ready.termsUpdatedNotice, isFalse);
    },
  );
}

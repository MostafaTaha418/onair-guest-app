import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/booking/domain/booking_quote.dart';
import 'package:on_air/features/booking/presentation/booking_flow_cubit.dart';
import 'package:on_air/features/listings/domain/property_details.dart';

import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_listings_repository.dart';

PropertyDetails _property1f() => PropertyDetails(
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

StayRange _threeNights() =>
    StayRange(DateOnly.parse('2026-11-20'), DateOnly.parse('2026-11-23'));

/// Delegates to the mock server but can fail the next quote with a chosen
/// error code.
final class FlakyFlowRepository implements BookingFlowRepository {
  FlakyFlowRepository(this._inner);

  final BookingFlowRepository _inner;
  String? nextQuoteError;

  @override
  Future<BookingQuote> quote({
    required String propertyId,
    required StayRange stay,
    required int guests,
    required String termsHash,
  }) async {
    final error = nextQuoteError;
    if (error != null) {
      nextQuoteError = null;
      throw AppFailure(ErrorMapper.fromCode(error));
    }
    return _inner.quote(
      propertyId: propertyId,
      stay: stay,
      guests: guests,
      termsHash: termsHash,
    );
  }

  @override
  Future<VerificationStatus> verificationStatus() =>
      _inner.verificationStatus();

  @override
  Future<PaymentSessionInfo> startPayment({
    required String quoteId,
    required String termsHash,
    required String attemptKey,
  }) => _inner.startPayment(
    quoteId: quoteId,
    termsHash: termsHash,
    attemptKey: attemptKey,
  );

  @override
  Future<PhoneChallenge> requestPhoneChange({
    required String phoneE164,
    required bool hasWhatsapp,
    String? whatsappE164,
  }) => _inner.requestPhoneChange(
    phoneE164: phoneE164,
    hasWhatsapp: hasWhatsapp,
    whatsappE164: whatsappE164,
  );

  @override
  Future<void> sendCode(String challengeId) => _inner.sendCode(challengeId);

  @override
  Future<void> verifyCode({
    required String challengeId,
    required String code,
  }) => _inner.verifyCode(challengeId: challengeId, code: code);
}

void main() {
  late FakeBookingBackend backend;
  late FakeConnectivity connectivity;
  late FakeListingsRepository listings;
  late FlakyFlowRepository flow;

  setUp(() {
    backend = FakeBookingBackend();
    connectivity = FakeConnectivity();
    listings = FakeListingsRepository();
    flow = FlakyFlowRepository(backend.server);
    listings.propertyResponses.add(_property1f());
    listings.unavailableNightsResponses.add(<DateOnly>{});
  });

  tearDown(() {
    backend.dispose();
    connectivity.dispose();
  });

  BookingFlowCubit buildCubit({
    StayRange? initialStay,
    int? initialGuests,
    DateOnly? today,
  }) => BookingFlowCubit(
    listings: listings,
    flow: flow,
    connectivity: connectivity.createCubit(),
    propertyId: '00000000-0000-4000-8000-00000000001f',
    termsHash: 'mock-terms-1',
    initialStay: initialStay,
    initialGuests: initialGuests,
    today: today == null ? null : () => today,
  );

  test('load reaches ready with the property and the initial draft', () async {
    final cubit = buildCubit(
      initialStay: _threeNights(),
      initialGuests: 2,
      today: DateOnly(2026, 11, 1),
    );
    await cubit.load();
    final state = cubit.state;
    expect(state.load, FlowLoad.ready);
    expect(state.property!.id, '00000000-0000-4000-8000-00000000001f');
    expect(state.stay, _threeNights());
    expect(state.guests, 2);
    expect(state.termsHash, 'mock-terms-1');
    expect(state.unavailable, isEmpty);
    expect(cubit.canContinue, isTrue);
    await cubit.close();
  });

  test('an unknown property is not available', () async {
    listings.propertyResponses.clear();
    listings.propertyResponses.add(
      AppFailure(ErrorMapper.fromCode('NOT_FOUND')),
    );
    final cubit = buildCubit();
    await cubit.load();
    expect(cubit.state.load, FlowLoad.notAvailable);
    await cubit.close();
  });

  test('canContinue requires a stay and the guest bounds', () async {
    final cubit = buildCubit(initialGuests: 2);
    await cubit.load();
    expect(cubit.state.stay, isNull);
    expect(cubit.canContinue, isFalse);

    cubit.setStay(_threeNights());
    expect(cubit.canContinue, isTrue);

    cubit.setGuests(99);
    // The stepper clamps to the property maximum.
    expect(cubit.state.guests, 6);
    expect(cubit.canContinue, isTrue);

    cubit.setGuests(0);
    expect(cubit.state.guests, 1);
    await cubit.close();
  });

  test('an unavailable night blocks continue', () async {
    listings.unavailableNightsResponses.clear();
    listings.unavailableNightsResponses.add({DateOnly.parse('2026-11-21')});
    final cubit = buildCubit(initialStay: _threeNights(), initialGuests: 2);
    await cubit.load();
    expect(cubit.canContinue, isFalse);
    await cubit.close();
  });

  test('requestQuote stores the server quote', () async {
    final cubit = buildCubit(
      initialStay: _threeNights(),
      initialGuests: 2,
      today: DateOnly(2026, 11, 1),
    );
    await cubit.load();
    expect(cubit.state.quoting, isFalse);
    final ok = await cubit.requestQuote();
    expect(ok, isTrue);
    expect(cubit.state.quoting, isFalse);
    expect(cubit.state.quote, isNotNull);
    expect(cubit.state.quote!.total, Money(450000));
    expect(cubit.state.quote!.payNow, Money(112500));
    expect(cubit.state.quote!.remaining, Money(337500));
    await cubit.close();
  });

  test('DATES_UNAVAILABLE shows the error and reloads availability', () async {
    final cubit = buildCubit(
      initialStay: _threeNights(),
      initialGuests: 2,
      today: DateOnly(2026, 11, 1),
    );
    await cubit.load();
    flow.nextQuoteError = 'DATES_UNAVAILABLE';
    final ok = await cubit.requestQuote();
    expect(ok, isFalse);
    expect(cubit.state.error!.code, ErrorCode.datesUnavailable);
    expect(cubit.state.quoting, isFalse);
    // The unavailable set was refetched: the second queued answer.
    expect(listings.unavailableNightsResponses, isEmpty);
    await cubit.close();
  });

  test('GUESTS_EXCEEDED shows the error without reloading', () async {
    final cubit = buildCubit(
      initialStay: _threeNights(),
      initialGuests: 2,
      today: DateOnly(2026, 11, 1),
    );
    await cubit.load();
    listings.unavailableNightsResponses.add(<DateOnly>{});
    flow.nextQuoteError = 'GUESTS_EXCEEDED';
    final ok = await cubit.requestQuote();
    expect(ok, isFalse);
    expect(cubit.state.error!.code, ErrorCode.guestsExceeded);
    // The availability list was not refetched.
    expect(listings.unavailableNightsResponses, hasLength(1));
    await cubit.close();
  });

  test('changing the stay or the guests drops the quote (T048)', () async {
    final cubit = buildCubit(
      initialStay: _threeNights(),
      initialGuests: 2,
      today: DateOnly(2026, 11, 1),
    );
    await cubit.load();
    await cubit.requestQuote();
    expect(cubit.state.quote, isNotNull);

    cubit.setStay(
      StayRange(DateOnly.parse('2026-11-20'), DateOnly.parse('2026-11-24')),
    );
    expect(cubit.state.quote, isNull);
    expect(cubit.state.pendingChange, isNull);
    expect(cubit.state.error, isNull);

    await cubit.requestQuote();
    expect(cubit.state.quote, isNotNull);
    cubit.setGuests(3);
    expect(cubit.state.quote, isNull);
    expect(cubit.state.pendingChange, isNull);
    await cubit.close();
  });
}

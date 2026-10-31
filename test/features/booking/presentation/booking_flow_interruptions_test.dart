import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/booking/domain/booking_quote.dart';
import 'package:on_air/features/booking/presentation/booking_flow_cubit.dart';
import 'package:on_air/features/listings/domain/property_details.dart';

import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_listings_repository.dart';

const _property1f = '00000000-0000-4000-8000-00000000001f';

StayRange _threeNights() =>
    StayRange(DateOnly.parse('2026-11-20'), DateOnly.parse('2026-11-23'));

PropertyDetails _property(String termsVersion) => PropertyDetails(
  id: _property1f,
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
  termsVersion: termsVersion,
);

/// Serves the scripted quotes in order (the last one repeats); everything
/// else delegates to fixed answers.
final class ScriptedFlow implements BookingFlowRepository {
  final List<BookingQuote> quotes = [];
  int quoteCalls = 0;

  @override
  Future<BookingQuote> quote({
    required String propertyId,
    required StayRange stay,
    required int guests,
    required String termsHash,
  }) async {
    quoteCalls++;
    if (quotes.isEmpty) {
      throw const AppFailure(
        ApiError(code: ErrorCode.internal, messageKey: 'INTERNAL'),
      );
    }
    return quotes.removeAt(0);
  }

  @override
  Future<VerificationStatus> verificationStatus() async =>
      const VerificationStatus(
        emailConfirmed: true,
        phoneConfirmed: true,
        email: 'guest@onair.test',
        phone: '+201012345678',
      );

  @override
  Future<PaymentSessionInfo> startPayment({
    required String quoteId,
    required String termsHash,
    required String attemptKey,
  }) => throw UnimplementedError();

  @override
  Future<PhoneChallenge> requestPhoneChange({
    required String phoneE164,
    required bool hasWhatsapp,
    String? whatsappE164,
  }) => throw UnimplementedError();

  @override
  Future<void> sendCode(String challengeId) => throw UnimplementedError();

  @override
  Future<void> verifyCode({
    required String challengeId,
    required String code,
  }) => throw UnimplementedError();
}

/// Loads the flow and quotes in one go: a single cubit reference keeps the
/// lint (and the reader) away from duplicated receivers.
Future<void> quoteAfterLoad(BookingFlowCubit cubit) async {
  await cubit.load();
  await cubit.requestQuote();
}

BookingQuote _quote({
  required DateTime expiresAt,
  Money? total,
  Money? payNow,
  Money? remaining,
  Money? nightly,
  String? termsHash,
  int id = 1,
}) => BookingQuote(
  quoteId: 'quote-$id',
  propertyId: _property1f,
  stay: _threeNights(),
  nights: 3,
  guests: 2,
  nightly: nightly ?? Money(150000),
  total: total ?? Money(450000),
  payNow: payNow ?? Money(112500),
  remaining: remaining ?? Money(337500),
  remainingDueAt: DateTime.utc(2026, 12),
  termsHash: termsHash ?? 'mock-terms-1',
  policySummary: null,
  expiresAt: expiresAt,
);

void main() {
  // A 2-minute quote TTL: the expiry refresh fires 30 s before the deadline.
  final start = DateTime.utc(2026, 11, 1, 10);
  DateTime expiresAt(FakeAsync async) =>
      start.add(async.elapsed).add(const Duration(minutes: 2));

  test('a changed re-quote 30 s before expiry parks in pendingChange', () {
    fakeAsync((async) {
      final connectivity = FakeConnectivity();
      final listings = FakeListingsRepository()
        ..propertyResponses.add(_property('mock-terms-1'))
        ..unavailableNightsResponses.add(<DateOnly>{});
      final flow = ScriptedFlow()
        ..quotes.add(_quote(expiresAt: expiresAt(async)));
      final cubit = BookingFlowCubit(
        listings: listings,
        flow: flow,
        connectivity: connectivity.createCubit(),
        propertyId: _property1f,
        termsHash: 'mock-terms-1',
        initialStay: _threeNights(),
        initialGuests: 2,
        now: () => start.add(async.elapsed),
      );
      unawaited(cubit.load());
      async.flushMicrotasks();
      expect(cubit.state.load, FlowLoad.ready);
      unawaited(cubit.requestQuote());
      async.flushMicrotasks();
      expect(flow.quoteCalls, 1);
      expect(cubit.state.quote!.quoteId, 'quote-1');
      expect(cubit.state.canPay, isTrue);

      // The server re-prices before the expiry: at T+90 s (30 s before the
      // deadline) the cubit refreshes on its own.
      flow.quotes.add(
        _quote(
          id: 2,
          expiresAt: DateTime.utc(2026, 11, 1, 11),
          nightly: Money(180000),
          total: Money(540000),
          payNow: Money(135000),
          remaining: Money(405000),
        ),
      );
      async.elapse(const Duration(seconds: 90));
      expect(flow.quoteCalls, 2);
      expect(cubit.state.quote!.quoteId, 'quote-2');
      expect(cubit.state.pendingChange, isNotNull);
      expect(cubit.state.canPay, isFalse);

      cubit.acceptChange();
      expect(cubit.state.pendingChange, isNull);
      expect(cubit.state.canPay, isTrue);

      unawaited(cubit.close());
      async.flushMicrotasks();
      connectivity.dispose();
    });
  });

  test('setStay drops the quote and cancels the old expiry refresh', () {
    fakeAsync((async) {
      final connectivity = FakeConnectivity();
      final listings = FakeListingsRepository()
        ..propertyResponses.add(_property('mock-terms-1'))
        ..unavailableNightsResponses.add(<DateOnly>{});
      final flow = ScriptedFlow()
        ..quotes.add(_quote(expiresAt: expiresAt(async)));
      final cubit = BookingFlowCubit(
        listings: listings,
        flow: flow,
        connectivity: connectivity.createCubit(),
        propertyId: _property1f,
        termsHash: 'mock-terms-1',
        initialStay: _threeNights(),
        initialGuests: 2,
        now: () => start.add(async.elapsed),
      );
      unawaited(quoteAfterLoad(cubit));
      async.flushMicrotasks();
      expect(cubit.state.quote!.quoteId, 'quote-1');

      // New dates: the quote and its expiry timer go.
      cubit.setStay(
        StayRange(DateOnly.parse('2026-11-20'), DateOnly.parse('2026-11-24')),
      );
      expect(cubit.state.quote, isNull);
      expect(cubit.state.pendingChange, isNull);

      // A re-priced answer waits in vain: the old expiry never fires.
      flow.quotes.add(_quote(id: 9, expiresAt: DateTime.utc(2026, 11, 1, 11)));
      async.elapse(const Duration(minutes: 3));
      expect(flow.quoteCalls, 1);
      expect(cubit.state.quote, isNull);

      unawaited(cubit.close());
      async.flushMicrotasks();
      connectivity.dispose();
    });
  });

  test('a fresh requestQuote clears a parked pendingChange', () {
    fakeAsync((async) {
      final connectivity = FakeConnectivity();
      final listings = FakeListingsRepository()
        ..propertyResponses.add(_property('mock-terms-1'))
        ..unavailableNightsResponses.add(<DateOnly>{});
      final flow = ScriptedFlow()
        ..quotes.add(_quote(expiresAt: expiresAt(async)));
      final cubit = BookingFlowCubit(
        listings: listings,
        flow: flow,
        connectivity: connectivity.createCubit(),
        propertyId: _property1f,
        termsHash: 'mock-terms-1',
        initialStay: _threeNights(),
        initialGuests: 2,
        now: () => start.add(async.elapsed),
      );
      unawaited(quoteAfterLoad(cubit));
      async.flushMicrotasks();

      // A changed re-quote parks in pendingChange.
      flow.quotes.add(
        _quote(
          id: 2,
          expiresAt: DateTime.utc(2026, 11, 1, 11),
          nightly: Money(180000),
          total: Money(540000),
          payNow: Money(135000),
          remaining: Money(405000),
        ),
      );
      unawaited(cubit.refreshQuote());
      async.flushMicrotasks();
      expect(cubit.state.pendingChange, isNotNull);

      // The guest asks for a fresh quote instead: the parked change goes.
      flow.quotes.add(_quote(id: 3, expiresAt: DateTime.utc(2026, 11, 1, 11)));
      unawaited(cubit.requestQuote());
      async.flushMicrotasks();
      expect(flow.quoteCalls, 3);
      expect(cubit.state.pendingChange, isNull);
      expect(cubit.state.quote!.quoteId, 'quote-3');
      expect(cubit.state.canPay, isTrue);

      unawaited(cubit.close());
      async.flushMicrotasks();
      connectivity.dispose();
    });
  });

  test('an identical re-quote does not set pendingChange', () {
    fakeAsync((async) {
      final connectivity = FakeConnectivity();
      final listings = FakeListingsRepository()
        ..propertyResponses.add(_property('mock-terms-1'))
        ..unavailableNightsResponses.add(<DateOnly>{});
      final flow = ScriptedFlow()
        ..quotes.add(_quote(expiresAt: expiresAt(async)))
        ..quotes.add(_quote(id: 2, expiresAt: DateTime.utc(2026, 11, 1, 11)));
      final cubit = BookingFlowCubit(
        listings: listings,
        flow: flow,
        connectivity: connectivity.createCubit(),
        propertyId: _property1f,
        termsHash: 'mock-terms-1',
        initialStay: _threeNights(),
        initialGuests: 2,
        now: () => start.add(async.elapsed),
      );
      unawaited(quoteAfterLoad(cubit));
      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 90));
      expect(flow.quoteCalls, 2);
      expect(cubit.state.pendingChange, isNull);
      expect(cubit.state.canPay, isTrue);

      unawaited(cubit.close());
      async.flushMicrotasks();
      connectivity.dispose();
    });
  });

  test('a payment-start quote-expiry error triggers refreshQuote', () {
    fakeAsync((async) {
      final connectivity = FakeConnectivity();
      final listings = FakeListingsRepository()
        ..propertyResponses.add(_property('mock-terms-1'))
        ..unavailableNightsResponses.add(<DateOnly>{});
      final flow = ScriptedFlow()
        ..quotes.add(_quote(expiresAt: expiresAt(async)));
      final cubit = BookingFlowCubit(
        listings: listings,
        flow: flow,
        connectivity: connectivity.createCubit(),
        propertyId: _property1f,
        termsHash: 'mock-terms-1',
        initialStay: _threeNights(),
        initialGuests: 2,
        now: () => start.add(async.elapsed),
      );
      unawaited(quoteAfterLoad(cubit));
      async.flushMicrotasks();

      flow.quotes.add(_quote(id: 3, expiresAt: DateTime.utc(2026, 11, 1, 11)));
      unawaited(
        cubit.onPaymentError(
          const ApiError(
            code: ErrorCode.quoteExpired,
            messageKey: 'QUOTE_EXPIRED',
          ),
        ),
      );
      async.flushMicrotasks();
      expect(flow.quoteCalls, 2);
      expect(cubit.state.quote!.quoteId, 'quote-3');

      unawaited(cubit.close());
      async.flushMicrotasks();
      connectivity.dispose();
    });
  });

  test('a payment-start terms-changed error reloads the property', () {
    fakeAsync((async) {
      final connectivity = FakeConnectivity();
      final listings = FakeListingsRepository()
        ..propertyResponses.add(_property('mock-terms-1'))
        ..unavailableNightsResponses.add(<DateOnly>{});
      final flow = ScriptedFlow()
        ..quotes.add(_quote(expiresAt: expiresAt(async)));
      final cubit = BookingFlowCubit(
        listings: listings,
        flow: flow,
        connectivity: connectivity.createCubit(),
        propertyId: _property1f,
        termsHash: 'mock-terms-1',
        initialStay: _threeNights(),
        initialGuests: 2,
        now: () => start.add(async.elapsed),
      );
      unawaited(quoteAfterLoad(cubit));
      async.flushMicrotasks();

      listings.propertyResponses.add(_property('mock-terms-2'));
      expect(cubit.state.termsChanged, isFalse);
      unawaited(
        cubit.onPaymentError(
          const ApiError(
            code: ErrorCode.termsChanged,
            messageKey: 'TERMS_CHANGED',
          ),
        ),
      );
      async.flushMicrotasks();
      expect(cubit.state.termsChanged, isTrue);
      expect(cubit.state.canPay, isFalse);
      expect(cubit.state.property!.termsVersion, 'mock-terms-2');

      // Accepting the new terms updates the hash and re-quotes.
      flow.quotes.add(_quote(id: 4, expiresAt: DateTime.utc(2026, 11, 1, 11)));
      unawaited(cubit.acceptNewTerms());
      async.flushMicrotasks();
      expect(cubit.state.termsChanged, isFalse);
      expect(cubit.state.termsHash, 'mock-terms-2');
      expect(flow.quoteCalls, 2);

      unawaited(cubit.close());
      async.flushMicrotasks();
      connectivity.dispose();
    });
  });

  test('the expiry timer is cancelled on close', () {
    fakeAsync((async) {
      final connectivity = FakeConnectivity();
      final listings = FakeListingsRepository()
        ..propertyResponses.add(_property('mock-terms-1'))
        ..unavailableNightsResponses.add(<DateOnly>{});
      final flow = ScriptedFlow()
        ..quotes.add(_quote(expiresAt: expiresAt(async)));
      final cubit = BookingFlowCubit(
        listings: listings,
        flow: flow,
        connectivity: connectivity.createCubit(),
        propertyId: _property1f,
        termsHash: 'mock-terms-1',
        initialStay: _threeNights(),
        initialGuests: 2,
        now: () => start.add(async.elapsed),
      );
      unawaited(quoteAfterLoad(cubit));
      async.flushMicrotasks();
      expect(flow.quoteCalls, 1);

      unawaited(cubit.close());
      async
        ..flushMicrotasks()
        ..elapse(const Duration(minutes: 5));
      expect(flow.quoteCalls, 1);
      connectivity.dispose();
    });
  });
}

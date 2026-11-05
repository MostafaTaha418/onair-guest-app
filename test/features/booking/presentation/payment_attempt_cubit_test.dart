import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/booking/domain/booking_quote.dart';
import 'package:on_air/features/booking/domain/payment_attempt.dart';
import 'package:on_air/features/booking/presentation/payment_attempt_cubit.dart';

import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_in_app_browser.dart';

/// Delegates to the mock server but can fail the next start request and
/// records the attempt keys it was asked to start.
final class RecordingFlowRepository implements BookingFlowRepository {
  RecordingFlowRepository(this._inner);

  final BookingFlowRepository _inner;
  final List<String> startedKeys = [];
  bool failNextStart = false;

  @override
  Future<PaymentSessionInfo> startPayment({
    required String quoteId,
    required String termsHash,
    required String attemptKey,
  }) async {
    startedKeys.add(attemptKey);
    if (failNextStart) {
      failNextStart = false;
      throw AppFailure(ErrorMapper.noResponse());
    }
    return _inner.startPayment(
      quoteId: quoteId,
      termsHash: termsHash,
      attemptKey: attemptKey,
    );
  }

  @override
  Future<PaymentSessionInfo> startRemainingPayment({
    required String bookingId,
    required String attemptKey,
  }) => _inner.startRemainingPayment(
    bookingId: bookingId,
    attemptKey: attemptKey,
  );

  @override
  Future<VerificationStatus> verificationStatus() =>
      _inner.verificationStatus();

  @override
  Future<BookingQuote> quote({
    required String propertyId,
    required StayRange stay,
    required int guests,
    required String termsHash,
  }) => _inner.quote(
    propertyId: propertyId,
    stay: stay,
    guests: guests,
    termsHash: termsHash,
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

final class _ThrowingFlowRepository implements BookingFlowRepository {
  @override
  Future<VerificationStatus> verificationStatus() async =>
      const VerificationStatus(
        emailConfirmed: true,
        phoneConfirmed: true,
        email: 'guest@mock.onair.test',
        phone: '+201000000001',
      );

  @override
  Future<BookingQuote> quote({
    required String propertyId,
    required StayRange stay,
    required int guests,
    required String termsHash,
  }) => throw UnimplementedError();

  @override
  Future<PaymentSessionInfo> startPayment({
    required String quoteId,
    required String termsHash,
    required String attemptKey,
  }) => throw AppFailure(ErrorMapper.noResponse());

  @override
  Future<PaymentSessionInfo> startRemainingPayment({
    required String bookingId,
    required String attemptKey,
  }) => throw AppFailure(ErrorMapper.noResponse());

  @override
  Future<PhoneChallenge> requestPhoneChange({
    required String phoneE164,
    required bool hasWhatsapp,
    String? whatsappE164,
  }) => throw UnimplementedError();

  @override
  Future<void> sendCode(String challengeId) async {}

  @override
  Future<void> verifyCode({
    required String challengeId,
    required String code,
  }) async {}
}

final class _RemainingFlowRepository implements BookingFlowRepository {
  _RemainingFlowRepository(this._inner);

  final BookingFlowRepository _inner;
  final List<String> keys = [];
  Future<void> Function()? beforeStart;
  Completer<PaymentSessionInfo>? hold;
  AppFailure? nextFailure;

  @override
  Future<PaymentSessionInfo> startRemainingPayment({
    required String bookingId,
    required String attemptKey,
  }) async {
    keys.add(attemptKey);
    await beforeStart?.call();
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      throw failure;
    }
    final pending = hold;
    if (pending != null) return pending.future;
    return _inner.startRemainingPayment(
      bookingId: bookingId,
      attemptKey: attemptKey,
    );
  }

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
  Future<VerificationStatus> verificationStatus() =>
      _inner.verificationStatus();

  @override
  Future<BookingQuote> quote({
    required String propertyId,
    required StayRange stay,
    required int guests,
    required String termsHash,
  }) => _inner.quote(
    propertyId: propertyId,
    stay: stay,
    guests: guests,
    termsHash: termsHash,
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
  late FakeInAppBrowser browser;
  late RecordingFlowRepository flow;
  late PaymentAttemptCubit cubit;
  var keyCounter = 0;
  var quoteCounter = 0;

  /// A quote the mock server actually holds; payment start validates the
  /// quote id against its own store (AC-023).
  Future<BookingQuote> quoteFor(String propertyId) => backend.server.quote(
    propertyId: propertyId,
    stay: StayRange(
      DateOnly.parse('2026-11-20').addDays(++quoteCounter),
      DateOnly.parse('2026-11-23').addDays(quoteCounter),
    ),
    guests: 2,
    termsHash: 'mock-terms-1',
  );

  setUp(() {
    backend = FakeBookingBackend(includeG3Fixtures: true);
    browser = FakeInAppBrowser();
    flow = RecordingFlowRepository(backend.server);
    keyCounter = 0;
    cubit = PaymentAttemptCubit(
      flow: flow,
      store: backend.paymentAttempts,
      browser: () => browser,
      logger: AppLogger(sink: (_) {}),
      newKey: () => 'key-${++keyCounter}'.padRight(36, '0'),
    );
  });

  tearDown(() {
    unawaited(cubit.close());
    backend.dispose();
  });

  const property1f = '00000000-0000-4000-8000-00000000001f';
  const property21 = '00000000-0000-4000-8000-000000000021';

  test('the attempt is saved before the start request', () async {
    final storedBefore = <PaymentAttempt?>[];
    final throwing = _ThrowingFlowRepository();
    final failingCubit = PaymentAttemptCubit(
      flow: throwing,
      store: backend.paymentAttempts,
      browser: () => browser,
      logger: AppLogger(sink: (_) {}),
      newKey: () => 'key-1'.padRight(36, '0'),
    );
    try {
      await failingCubit.pay(await quoteFor(property1f));
    } on Object {
      // The repository throws on purpose.
    }
    storedBefore.add(await backend.paymentAttempts.read());
    expect(storedBefore.single, isNotNull);
    expect(storedBefore.single!.attemptKey, 'key-1'.padRight(36, '0'));
    await failingCubit.close();
  });

  test('a double tap starts one payment session', () async {
    final quote = await quoteFor(property1f);
    // Both taps land before the first request finishes.
    final first = cubit.pay(quote);
    final second = cubit.pay(quote);
    await first;
    await second;
    expect(flow.startedKeys, hasLength(1));
    expect(backend.server.sessionCount(flow.startedKeys.first), 1);
  });

  blocTest<PaymentAttemptCubit, PaymentAttemptState>(
    'a network failure emits AttemptFailed and a retry reuses the key',
    build: () => cubit,
    act: (cubit) async {
      final quote = await quoteFor(property1f);
      flow.failNextStart = true;
      await cubit.pay(quote);
      await cubit.pay(quote);
    },
    expect: () => [
      isA<AttemptStarting>(),
      isA<AttemptFailed>(),
      isA<AttemptStarting>(),
      isA<AttemptOpened>(),
    ],
    verify: (_) async {
      expect(flow.startedKeys, hasLength(2));
      expect(flow.startedKeys[0], flow.startedKeys[1]);
      expect(backend.server.sessionCount(flow.startedKeys.first), 1);
      final stored = await backend.paymentAttempts.read();
      expect(stored!.attemptKey, flow.startedKeys.first);
    },
  );

  test('a different quote gets a fresh attempt key', () async {
    await cubit.pay(await quoteFor(property1f));
    await cubit.pay(await quoteFor(property21));
    expect(flow.startedKeys, hasLength(2));
    expect(flow.startedKeys[0], isNot(flow.startedKeys[1]));
  });

  test('success opens the browser with the session url once', () async {
    await cubit.pay(await quoteFor(property1f));
    final state = cubit.state;
    expect(state, isA<AttemptOpened>());
    final attempt = (state as AttemptOpened).attempt;
    expect(attempt.bookingId, isNotNull);
    final stored = await backend.paymentAttempts.read();
    expect(stored!.bookingId, attempt.bookingId);
    expect(browser.opened, hasLength(1));
    expect(
      browser.opened.single.url,
      Uri.parse('https://pay.mock.onair.test/session/${attempt.bookingId}'),
    );
    expect(browser.opened.single.bookingId, attempt.bookingId);
  });

  test('finish and newAttempt clear the store and go idle', () async {
    await cubit.pay(await quoteFor(property1f));
    await cubit.finish();
    expect(cubit.state, isA<AttemptIdle>());
    expect(await backend.paymentAttempts.read(), isNull);

    await cubit.pay(await quoteFor(property1f));
    await cubit.newAttempt();
    expect(cubit.state, isA<AttemptIdle>());
    expect(await backend.paymentAttempts.read(), isNull);
  });

  test('restore emits AttemptReturned for an attempt with a booking', () async {
    final attempt = PaymentAttempt(
      attemptKey: 'key-9'.padRight(36, '0'),
      quoteId: 'quote-x',
      propertyId: property1f,
      termsHash: 'mock-terms-1',
      bookingId: 'b0000000-0000-4000-8000-000000000099',
      startedAt: DateTime.utc(2026, 11, 1, 9),
    );
    await backend.paymentAttempts.save(attempt);
    final restored = PaymentAttemptCubit(
      flow: flow,
      store: backend.paymentAttempts,
      browser: () => browser,
      logger: AppLogger(sink: (_) {}),
    );
    await restored.restore();
    expect(restored.state, isA<AttemptReturned>());
    expect((restored.state as AttemptReturned).attempt, attempt);
    expect(browser.opened, isEmpty);
    await restored.close();
  });

  test('restore stays idle for an attempt without a booking', () async {
    final attempt = PaymentAttempt(
      attemptKey: 'key-8'.padRight(36, '0'),
      quoteId: 'quote-x',
      propertyId: property1f,
      termsHash: 'mock-terms-1',
      startedAt: DateTime.utc(2026, 11, 1, 9),
    );
    await backend.paymentAttempts.save(attempt);
    final restored = PaymentAttemptCubit(
      flow: flow,
      store: backend.paymentAttempts,
      browser: () => browser,
      logger: AppLogger(sink: (_) {}),
    );
    await restored.restore();
    expect(restored.state, isA<AttemptIdle>());
    await restored.close();
  });

  test('markReturned moves AttemptOpened to AttemptReturned and keeps the '
      'record', () async {
    await cubit.pay(await quoteFor(property1f));
    final attempt = (cubit.state as AttemptOpened).attempt;
    cubit.markReturned();
    expect(cubit.state, isA<AttemptReturned>());
    expect((cubit.state as AttemptReturned).attempt, attempt);
    expect(await backend.paymentAttempts.read(), attempt);
  });

  test('markReturned does nothing when no attempt is open', () async {
    cubit.markReturned();
    expect(cubit.state, isA<AttemptIdle>());
  });

  test('syncWithStore goes idle only when the store is empty', () async {
    await cubit.pay(await quoteFor(property1f));
    cubit.markReturned();
    // A non-empty store leaves the returned state alone.
    await cubit.syncWithStore();
    expect(cubit.state, isA<AttemptReturned>());

    // The server decided elsewhere: the store is empty, the state follows.
    await backend.paymentAttempts.clear();
    await cubit.syncWithStore();
    expect(cubit.state, isA<AttemptIdle>());

    // Idempotent: syncing again does not emit or re-trigger anything.
    await cubit.syncWithStore();
    expect(cubit.state, isA<AttemptIdle>());
  });

  group('payRemaining', () {
    const booking20 = 'b0000000-0000-4000-8000-000000000020';
    const booking23 = 'b0000000-0000-4000-8000-000000000023';

    late _RemainingFlowRepository remainingFlow;
    late PaymentAttemptCubit remainingCubit;

    setUp(() {
      remainingFlow = _RemainingFlowRepository(backend.server);
      remainingCubit = PaymentAttemptCubit(
        flow: remainingFlow,
        store: backend.paymentAttempts,
        browser: () => browser,
        logger: AppLogger(sink: (_) {}),
        newKey: () => 'remaining-${++keyCounter}'.padRight(36, '0'),
      );
    });

    tearDown(() => remainingCubit.close());

    test('saves remaining record before repository call', () async {
      PaymentAttempt? saved;
      remainingFlow.beforeStart = () async {
        saved = await backend.paymentAttempts.read();
      };

      await remainingCubit.payRemaining(booking20);

      expect(saved?.kind, PaymentKind.remaining);
      expect(saved?.bookingId, booking20);
    });

    test('rapid second start makes one repository call', () async {
      remainingFlow.hold = Completer<PaymentSessionInfo>();
      final first = remainingCubit.payRemaining(booking20);
      final second = remainingCubit.payRemaining(booking20);
      await Future<void>.delayed(Duration.zero);
      expect(remainingFlow.keys, hasLength(1));
      remainingFlow.hold!.complete(
        PaymentSessionInfo(
          bookingId: booking20,
          paymentId: 'p1',
          paymentUrl: Uri.parse('https://pay.test/remaining'),
          paymentUrlExpiresAt: DateTime.utc(2026, 11, 1, 10, 30),
        ),
      );
      await Future.wait([first, second]);
    });

    test('reuses only a remaining attempt for the same booking', () async {
      final stored = PaymentAttempt.remaining(
        attemptKey: 'stored-key'.padRight(36, '0'),
        bookingId: booking20,
        startedAt: DateTime.utc(2026, 11, 1, 9),
      );
      await backend.paymentAttempts.save(stored);
      await remainingCubit.payRemaining(booking20);
      expect(remainingFlow.keys.single, stored.attemptKey);

      await remainingCubit.finish();
      await backend.paymentAttempts.save(
        PaymentAttempt.remaining(
          attemptKey: 'other-key'.padRight(36, '0'),
          bookingId: booking23,
          startedAt: DateTime.utc(2026, 11, 1, 9),
        ),
      );
      await remainingCubit.payRemaining(booking20);
      expect(remainingFlow.keys.last, isNot('other-key'.padRight(36, '0')));

      await remainingCubit.finish();
      await backend.paymentAttempts.save(
        PaymentAttempt(
          attemptKey: 'initial-key'.padRight(36, '0'),
          quoteId: 'q',
          propertyId: property1f,
          termsHash: 't',
          bookingId: booking20,
          startedAt: DateTime.utc(2026, 11, 1, 9),
        ),
      );
      await remainingCubit.payRemaining(booking20);
      expect(remainingFlow.keys.last, isNot('initial-key'.padRight(36, '0')));
    });

    test(
      'success saves session fields, emits opened, and opens once',
      () async {
        await remainingCubit.payRemaining(booking20);

        expect(remainingCubit.state, isA<AttemptOpened>());
        final attempt = (remainingCubit.state as AttemptOpened).attempt;
        expect(attempt.paymentId, isNotNull);
        expect(attempt.paymentUrl, contains('/remaining/$booking20'));
        expect(attempt.paymentUrlExpiresAt, isNotNull);
        expect(await backend.paymentAttempts.read(), attempt);
        expect(browser.opened, hasLength(1));
      },
    );

    test('conflict emits AttemptFailed with conflict code', () async {
      remainingFlow.nextFailure = AppFailure(
        ErrorMapper.fromCode('CONFLICT'),
      );

      await remainingCubit.payRemaining(booking20);

      expect(remainingCubit.state, isA<AttemptFailed>());
      expect(
        (remainingCubit.state as AttemptFailed).error.code,
        ErrorCode.conflict,
      );
    });
  });
}

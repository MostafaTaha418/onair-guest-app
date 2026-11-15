import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/booking/domain/booking_quote.dart';
import 'package:on_air/features/booking/presentation/verify_identity_cubit.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_booking_backend.dart';

/// Serves a canned verification status and delegates the rest — the mock
/// server only flips both flags at once (S005 US6 removed the booking-flow
/// phone challenge: the phone step is a WhatsApp redirect card).
final class StatusFlowRepository implements BookingFlowRepository {
  StatusFlowRepository(this._inner);

  final BookingFlowRepository _inner;
  VerificationStatus? statusOverride;

  @override
  Future<VerificationStatus> verificationStatus() async =>
      statusOverride ?? await _inner.verificationStatus();

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
  Future<PaymentSessionInfo> startRemainingPayment({
    required String bookingId,
    required String attemptKey,
  }) => _inner.startRemainingPayment(
    bookingId: bookingId,
    attemptKey: attemptKey,
  );
}

void main() {
  late FakeBookingBackend backend;
  late FakeAuthRepository auth;
  late StatusFlowRepository flow;

  setUp(() {
    backend = FakeBookingBackend(startVerified: false);
    auth = FakeAuthRepository();
    flow = StatusFlowRepository(backend.server);
  });

  tearDown(() => backend.dispose());

  VerifyIdentityCubit buildCubit() =>
      VerifyIdentityCubit(flow: flow, auth: auth);

  const emailOnly = VerificationStatus(
    emailConfirmed: true,
    phoneConfirmed: false,
    email: 'guest@mock.onair.test',
    phone: '+201000000001',
  );

  test('start with an unconfirmed email lands on the email step', () async {
    final cubit = buildCubit();
    await cubit.start();
    final state = cubit.state;
    expect(state, isA<VerifyEmailStep>());
    expect((state as VerifyEmailStep).email, 'guest@mock.onair.test');
    await cubit.close();
  });

  test(
    'start with a confirmed email and an unconfirmed phone lands on the WhatsApp card',
    () async {
      flow.statusOverride = emailOnly;
      final cubit = buildCubit();
      await cubit.start();
      expect(cubit.state, isA<VerifyPhoneStep>());
      await cubit.close();
    },
  );

  test('start with everything confirmed is done', () async {
    flow.statusOverride = const VerificationStatus(
      emailConfirmed: true,
      phoneConfirmed: true,
      email: 'guest@mock.onair.test',
      phone: '+201000000001',
    );
    final cubit = buildCubit();
    await cubit.start();
    expect(cubit.state, isA<VerifyDone>());
    await cubit.close();
  });
}

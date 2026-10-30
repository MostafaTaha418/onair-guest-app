import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/booking/domain/booking_quote.dart';
import 'package:on_air/features/booking/presentation/verify_identity_cubit.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_booking_backend.dart';

/// Delegates to the mock server but records the phone-change arguments,
/// counts sendCode calls, can fail the next sendCode with a chosen failure,
/// and can override the reported verification status (the mock server only
/// flips both flags at once).
final class RecordingFlowRepository implements BookingFlowRepository {
  RecordingFlowRepository(this._inner);

  final BookingFlowRepository _inner;
  String? requestedPhone;
  bool? requestedHasWhatsapp;
  String? requestedWhatsapp;
  int sendCodeCalls = 0;
  AppFailure? nextSendCodeError;
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
  Future<PhoneChallenge> requestPhoneChange({
    required String phoneE164,
    required bool hasWhatsapp,
    String? whatsappE164,
  }) async {
    requestedPhone = phoneE164;
    requestedHasWhatsapp = hasWhatsapp;
    requestedWhatsapp = whatsappE164;
    return _inner.requestPhoneChange(
      phoneE164: phoneE164,
      hasWhatsapp: hasWhatsapp,
      whatsappE164: whatsappE164,
    );
  }

  @override
  Future<void> sendCode(String challengeId) async {
    sendCodeCalls++;
    final error = nextSendCodeError;
    if (error != null) {
      nextSendCodeError = null;
      throw error;
    }
    await _inner.sendCode(challengeId);
  }

  @override
  Future<void> verifyCode({
    required String challengeId,
    required String code,
  }) => _inner.verifyCode(challengeId: challengeId, code: code);
}

void main() {
  late FakeBookingBackend backend;
  late FakeAuthRepository auth;
  late RecordingFlowRepository flow;

  setUp(() {
    backend = FakeBookingBackend(startVerified: false);
    auth = FakeAuthRepository();
    flow = RecordingFlowRepository(backend.server);
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
    'start with a confirmed email and an unconfirmed phone lands on the phone step',
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

  test(
    'a valid phone with WhatsApp requests +201012345678 and sends the code',
    () async {
      flow.statusOverride = emailOnly;
      final cubit = buildCubit();
      await cubit.start();
      await cubit.submitPhone('0101 234 5678', hasWhatsapp: true);
      expect(flow.requestedPhone, '+201012345678');
      expect(flow.requestedHasWhatsapp, isTrue);
      expect(flow.requestedWhatsapp, isNull);
      expect(flow.sendCodeCalls, 1);
      final state = cubit.state;
      expect(state, isA<VerifyCodeStep>());
      expect((state as VerifyCodeStep).challengeId, 'challenge-1');
      expect(state.retryAfter, const Duration(seconds: 60));
      await cubit.close();
    },
  );

  test(
    'a locally invalid phone shows the country error without calling the server',
    () async {
      flow.statusOverride = emailOnly;
      final cubit = buildCubit();
      await cubit.start();
      await cubit.submitPhone('0123', hasWhatsapp: true);
      final state = cubit.state;
      expect(state, isA<VerifyPhoneStep>());
      expect(
        (state as VerifyPhoneStep).error,
        ErrorCode.phoneCountryNotSupported,
      );
      expect(flow.requestedPhone, isNull);
      expect(flow.sendCodeCalls, 0);
      await cubit.close();
    },
  );

  test('the WhatsApp number is sent only when the switch is off', () async {
    flow.statusOverride = emailOnly;
    final cubit = buildCubit();
    await cubit.start();
    await cubit.submitPhone(
      '01012345678',
      hasWhatsapp: false,
      whatsapp: '0111 234 5678',
    );
    expect(flow.requestedWhatsapp, '+201112345678');
    await cubit.close();
  });

  test('a WhatsApp number is ignored while the switch is on', () async {
    flow.statusOverride = emailOnly;
    final cubit = buildCubit();
    await cubit.start();
    await cubit.submitPhone(
      '01012345678',
      hasWhatsapp: true,
      whatsapp: '01112345678',
    );
    expect(flow.requestedWhatsapp, isNull);
    await cubit.close();
  });

  test('a phone the server already knows shows phoneAlreadyUsed', () async {
    flow.statusOverride = emailOnly;
    final cubit = buildCubit();
    await cubit.start();
    await cubit.submitPhone('+201000000000', hasWhatsapp: true);
    final state = cubit.state;
    expect(state, isA<VerifyPhoneStep>());
    expect((state as VerifyPhoneStep).error, ErrorCode.phoneAlreadyUsed);
    expect(state.sending, isFalse);
    await cubit.close();
  });

  test(
    'a wrong code keeps the code step with otpInvalid; the right one finishes',
    () async {
      flow.statusOverride = emailOnly;
      final cubit = buildCubit();
      await cubit.start();
      await cubit.submitPhone('01012345678', hasWhatsapp: true);
      await cubit.submitCode('000000');
      final state = cubit.state;
      expect(state, isA<VerifyCodeStep>());
      expect((state as VerifyCodeStep).error, ErrorCode.otpInvalid);
      expect(state.verifying, isFalse);

      flow.statusOverride = null; // the re-check reads the server's own status
      await cubit.submitCode('123456');
      expect(cubit.state, isA<VerifyDone>());
      await cubit.close();
    },
  );

  test(
    'RATE_LIMITED on sendCode keeps the code step and exposes retryAfter',
    () async {
      flow
        ..statusOverride = emailOnly
        ..nextSendCodeError = const AppFailure(
          ApiError(
            code: ErrorCode.rateLimited,
            messageKey: '',
            retryAfter: Duration(seconds: 30),
          ),
        );
      final cubit = buildCubit();
      await cubit.start();
      await cubit.submitPhone('01012345678', hasWhatsapp: true);
      final state = cubit.state;
      expect(state, isA<VerifyCodeStep>());
      expect((state as VerifyCodeStep).challengeId, 'challenge-1');
      expect(state.error, ErrorCode.rateLimited);
      expect(state.retryAfter, const Duration(seconds: 30));
      await cubit.close();
    },
  );
}

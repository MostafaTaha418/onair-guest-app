import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/features/auth/phone_verification/presentation/phone_verification_cubit.dart';

final class _FakeRepository implements PhoneVerificationRepository {
  Exception? startError;
  Exception? sendError;
  Exception? verifyError;
  int sendCalls = 0;
  int statusCalls = 0;
  int verifyCalls = 0;
  DeliveryStatus statusAnswer = DeliveryStatus.pending;
  DeliveryFailure? statusFailure;
  GuestAccount verifyAccount = GuestAccount(
    id: 'guest',
    status: AccountStatus.active,
    phone: '+201012345678',
    phoneVerified: true,
    email: 'guest@example.com',
    emailVerified: true,
    fullName: 'Mona Adel',
    acceptedTermsVersion: 'v1',
  );

  @override
  Future<String> start(
    PhoneVerificationDraft draft,
    PhoneVerificationPurpose purpose,
  ) async {
    if (startError case final error?) throw error;
    return 'challenge-1';
  }

  @override
  Future<WhatsAppChallenge> send(String challengeId) async {
    sendCalls += 1;
    if (sendError case final error?) throw error;
    final now = DateTime.utc(2026, 11, 14, 10);
    return WhatsAppChallenge(
      challengeId: challengeId,
      maskedPhone: '+20 10•• ••• 678',
      expiresAt: now.add(const Duration(minutes: 10)),
      window: SendWindow(
        serverTime: now,
        nextSendAt: now.add(const Duration(seconds: 30)),
      ),
    );
  }

  @override
  Future<(DeliveryStatus, DeliveryFailure?, SendWindow)> status(
    String challengeId,
  ) async {
    statusCalls += 1;
    return (
      statusAnswer,
      statusFailure,
      SendWindow(
        serverTime: DateTime.utc(2026, 11, 14, 10),
        nextSendAt: DateTime.utc(2026, 11, 14, 10).add(
          const Duration(seconds: 30),
        ),
      ),
    );
  }

  @override
  Future<GuestAccount> verify(String challengeId, String code) async {
    verifyCalls += 1;
    if (verifyError case final error?) throw error;
    return verifyAccount;
  }
}

PhoneVerificationCubit _cubit(
  _FakeRepository repo, {
  PhoneVerificationPurpose purpose = PhoneVerificationPurpose.register,
  VoidCallback? onRegistered,
  VoidCallback? onChanged,
}) => PhoneVerificationCubit(
  repo,
  purpose: purpose,
  needsName: false,
  needsTerms: false,
  locale: 'ar',
  currentTermsVersion: 'v1',
  onRegistered: onRegistered,
  onChanged: onChanged,
);

/// Reaches the code step: a valid form submit runs start → send → PvCode.
Future<_FakeRepository> _reachCodeStep(
  PhoneVerificationCubit cubit,
  _FakeRepository repo,
) async {
  cubit.onPhoneChanged('01012345678');
  await cubit.submit();
  return repo;
}

void main() {
  test('a valid submit calls send and lands on PvCode', () async {
    final repo = _FakeRepository();
    final cubit = _cubit(repo);
    await _reachCodeStep(cubit, repo);

    expect(repo.sendCalls, 1);
    expect(cubit.state, isA<PvCode>());
    final code = cubit.state as PvCode;
    expect(code.challenge.challengeId, 'challenge-1');
    expect(code.challenge.maskedPhone, '+20 10•• ••• 678');
    await cubit.close();
  });

  test('polling runs every 5 s and stops at the first delivered status', () {
    fakeAsync((async) {
      final repo = _FakeRepository()..statusAnswer = DeliveryStatus.delivered;
      final cubit = _cubit(repo);
      unawaited(_reachCodeStep(cubit, repo));
      async
        ..elapse(const Duration(milliseconds: 10))
        ..elapse(const Duration(seconds: 5))
        ..elapse(Duration.zero);
      expect(repo.statusCalls, 1);
      final deliveredAt = repo.statusCalls;

      async
        ..elapse(const Duration(seconds: 30))
        ..elapse(Duration.zero);
      expect(repo.statusCalls, deliveredAt, reason: 'delivered stops polling');
      unawaited(cubit.close());
      async.elapse(const Duration(milliseconds: 10));
    });
  });

  test('polling gives up after 60 s (12 ticks)', () {
    fakeAsync((async) {
      final repo = _FakeRepository();
      final cubit = _cubit(repo);
      unawaited(_reachCodeStep(cubit, repo));
      async
        ..elapse(const Duration(milliseconds: 10))
        ..elapse(const Duration(seconds: 60))
        ..elapse(Duration.zero);
      expect(repo.statusCalls, 12);
      unawaited(cubit.close());
      async.elapse(const Duration(milliseconds: 10));
    });
  });

  test('a failed/not-on-WhatsApp poll shows the notice and stops', () {
    fakeAsync((async) {
      final repo = _FakeRepository()
        ..statusAnswer = DeliveryStatus.failed
        ..statusFailure = DeliveryFailure.notOnWhatsApp;
      final cubit = _cubit(repo);
      unawaited(_reachCodeStep(cubit, repo));
      async
        ..elapse(const Duration(milliseconds: 10))
        ..elapse(const Duration(seconds: 5));
      final code = cubit.state as PvCode;
      expect(code.notice, PvNotice.notOnWhatsApp);

      async
        ..elapse(const Duration(seconds: 30))
        ..elapse(Duration.zero);
      expect(repo.statusCalls, 1, reason: 'the failed poll stops polling');
      unawaited(cubit.close());
      async.elapse(const Duration(milliseconds: 10));
    });
  });

  test(
    'APP_ATTESTATION_FAILED and OTP_TEMPORARILY_UNAVAILABLE map to notices',
    () async {
      for (final (serverCode, notice) in [
        ('APP_ATTESTATION_FAILED', PvNotice.attestationFailed),
        ('OTP_TEMPORARILY_UNAVAILABLE', PvNotice.temporarilyUnavailable),
      ]) {
        final repo = _FakeRepository();
        final cubit = _cubit(repo);
        await _reachCodeStep(cubit, repo);

        // The resend path shares the send-error mapping (T054).
        repo.sendError = AppFailure(ErrorMapper.fromCode(serverCode));
        await cubit.resend();

        expect((cubit.state as PvCode).notice, notice, reason: serverCode);
        await cubit.close();
      }
    },
  );

  test('verify error keys follow the T050 table', () async {
    final expected = <String, String>{
      'OTP_INVALID': 'authOtpInvalid',
      'OTP_EXPIRED': 'authOtpExpired',
      'OTP_SUPERSEDED': 'whatsappUseLatestCode',
      'OTP_ATTEMPTS_EXCEEDED': 'otpAttemptsExceeded',
    };
    for (final MapEntry(key: serverCode, value: errorKey) in expected.entries) {
      final repo = _FakeRepository();
      final cubit = _cubit(repo);
      await _reachCodeStep(cubit, repo);
      repo.verifyError = AppFailure(ErrorMapper.fromCode(serverCode));
      cubit.onCodeChanged('123456');
      await cubit.verify();

      final code = cubit.state as PvCode;
      expect(code.errorKey, errorKey, reason: serverCode);
      expect(
        code.codeFieldEnabled,
        serverCode != 'OTP_ATTEMPTS_EXCEEDED',
        reason: serverCode,
      );
      await cubit.close();
    }
  });

  test(
    'PHONE_ALREADY_USED at verify returns to the form with the draft',
    () async {
      final repo = _FakeRepository();
      final cubit = _cubit(repo)..onPhoneChanged('01012345678');
      await cubit.submit();
      repo.verifyError = AppFailure(ErrorMapper.fromCode('PHONE_ALREADY_USED'));
      cubit.onCodeChanged('123456');
      await cubit.verify();

      expect(cubit.state, isA<PvForm>());
      final form = cubit.state as PvForm;
      expect(form.phoneText, '01012345678');
      expect(form.phoneErrorKey, 'authPhoneAlreadyUsed');
      await cubit.close();
    },
  );

  test(
    'a successful verify emits PvDone and fires the purpose callback',
    () async {
      var registered = 0;
      var changed = 0;
      final account = GuestAccount(
        id: 'guest',
        status: AccountStatus.active,
        phone: '+201012345678',
        phoneVerified: true,
        email: 'guest@example.com',
        emailVerified: true,
      );

      final registerRepo = _FakeRepository()..verifyAccount = account;
      final registerCubit = _cubit(
        registerRepo,
        onRegistered: () => registered += 1,
      );
      await _reachCodeStep(registerCubit, registerRepo);
      registerCubit.onCodeChanged('123456');
      await registerCubit.verify();
      expect(registerCubit.state, isA<PvDone>());
      expect(registered, 1);
      expect(changed, 0);
      await registerCubit.close();

      final changeRepo = _FakeRepository()..verifyAccount = account;
      final changeCubit = _cubit(
        changeRepo,
        purpose: PhoneVerificationPurpose.change,
        onChanged: () => changed += 1,
      );
      await _reachCodeStep(changeCubit, changeRepo);
      changeCubit.onCodeChanged('123456');
      await changeCubit.verify();
      expect(changed, 1);
      await changeCubit.close();
    },
  );

  test('«تعديل الرقم» returns to the form with the previous draft', () async {
    final repo = _FakeRepository();
    final cubit = _cubit(repo)..onPhoneChanged('01012345678');
    await cubit.submit();
    cubit.editNumber();

    expect(cubit.state, isA<PvForm>());
    expect((cubit.state as PvForm).phoneText, '01012345678');
    expect(repo.statusCalls, isZero);
    await cubit.close();
  });

  test('close() cancels the polling timer', () {
    fakeAsync((async) {
      final repo = _FakeRepository();
      final cubit = _cubit(repo);
      unawaited(_reachCodeStep(cubit, repo));
      async.elapse(const Duration(milliseconds: 10));
      final atCode = repo.statusCalls;

      unawaited(cubit.close());
      async
        ..elapse(const Duration(seconds: 60))
        ..elapse(Duration.zero);
      expect(repo.statusCalls, atCode, reason: 'no ticks after close');
    });
  });
}

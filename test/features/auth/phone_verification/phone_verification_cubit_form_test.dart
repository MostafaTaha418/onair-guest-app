import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/features/auth/domain/egypt_phone.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/features/auth/phone_verification/presentation/phone_verification_cubit.dart';

final class _FakeRepository implements PhoneVerificationRepository {
  Exception? startError;
  int sendCalls = 0;
  int startCalls = 0;
  PhoneVerificationDraft? lastDraft;
  PhoneVerificationPurpose? lastPurpose;

  @override
  Future<String> start(
    PhoneVerificationDraft draft,
    PhoneVerificationPurpose purpose,
  ) async {
    startCalls += 1;
    lastDraft = draft;
    lastPurpose = purpose;
    if (startError case final error?) throw error;
    return 'challenge-1';
  }

  @override
  Future<WhatsAppChallenge> send(String challengeId) async {
    sendCalls += 1;
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
  ) => throw UnimplementedError();

  @override
  Future<GuestAccount> verify(String challengeId, String code) =>
      throw UnimplementedError();
}

PhoneVerificationCubit _cubit(
  _FakeRepository repo, {
  bool needsName = false,
  bool needsTerms = false,
  String? prefilledName,
  VoidCallback? onAlreadyComplete,
}) => PhoneVerificationCubit(
  repo,
  purpose: PhoneVerificationPurpose.register,
  needsName: needsName,
  needsTerms: needsTerms,
  locale: 'ar',
  currentTermsVersion: 'v1',
  prefilledName: prefilledName,
  onAlreadyComplete: onAlreadyComplete,
);

void main() {
  late _FakeRepository repo;

  setUp(() => repo = _FakeRepository());

  test('the initial state is an idle PvForm with the prefilled name', () async {
    final cubit = _cubit(repo, prefilledName: 'Mona Adel');
    expect(cubit.state, isA<PvForm>());
    final form = cubit.state as PvForm;
    expect(form.nameText, 'Mona Adel');
    expect(form.phoneText, isEmpty);
    expect(form.submitting, isFalse);
    expect(form.termsChanged, isFalse);
    await cubit.close();
  });

  blocTest<PhoneVerificationCubit, PvState>(
    'an invalid phone shows a field error and never reaches the repository',
    build: () => _cubit(repo),
    act: (cubit) async {
      cubit.onPhoneChanged('123');
      await cubit.submit();
    },
    verify: (_) => expect(repo.startCalls, 0),
    expect: () => [
      isA<PvForm>().having((s) => s.phoneText, 'phone', '123'),
      isA<PvForm>().having(
        (s) => s.phoneErrorKey,
        'phoneError',
        'authPhoneInvalid',
      ),
    ],
  );

  blocTest<PhoneVerificationCubit, PvState>(
    'the name is required only when the account misses one',
    build: () => _cubit(repo, needsName: true),
    act: (cubit) async {
      cubit.onPhoneChanged('01012345678');
      await cubit.submit(); // no name at all
      cubit.onNameChanged('a'); // too short
      await cubit.submit();
      cubit.onNameChanged('Mona Adel');
      await cubit.submit();
    },
    verify: (_) {
      expect(repo.startCalls, 1);
      expect(repo.lastDraft!.fullName, 'Mona Adel');
    },
    expect: () => [
      isA<PvForm>().having((s) => s.phoneText, 'phone', '01012345678'),
      isA<PvForm>().having(
        (s) => s.nameErrorKey,
        'nameError',
        'authFieldRequired',
      ),
      isA<PvForm>().having((s) => s.nameText, 'name', 'a'),
      isA<PvForm>().having(
        (s) => s.nameErrorKey,
        'nameError',
        'authNameInvalid',
      ),
      isA<PvForm>().having((s) => s.nameText, 'name', 'Mona Adel'),
      isA<PvForm>().having((s) => s.submitting, 'submitting', true),
      isA<PvCode>(),
    ],
  );

  blocTest<PhoneVerificationCubit, PvState>(
    'the terms are required only when the account accepted none',
    build: () => _cubit(repo, needsTerms: true),
    act: (cubit) async {
      cubit.onPhoneChanged('01012345678');
      await cubit.submit(); // terms not accepted
      cubit.onTermsChanged(accepted: true);
      await cubit.submit();
    },
    verify: (_) {
      expect(repo.startCalls, 1);
      expect(repo.lastDraft!.acceptedTermsVersion, 'v1');
    },
    expect: () => [
      isA<PvForm>().having((s) => s.phoneText, 'phone', '01012345678'),
      isA<PvForm>(),
      isA<PvForm>().having((s) => s.termsAccepted, 'accepted', true),
      isA<PvForm>().having((s) => s.submitting, 'submitting', true),
      isA<PvCode>(),
    ],
  );

  blocTest<PhoneVerificationCubit, PvState>(
    'PHONE_ALREADY_USED returns to the form with a phone field error',
    build: () {
      repo.startError = AppFailure(ErrorMapper.fromCode('PHONE_ALREADY_USED'));
      return _cubit(repo);
    },
    act: (cubit) async {
      cubit.onPhoneChanged('01011111111');
      await cubit.submit();
    },
    expect: () => [
      isA<PvForm>().having((s) => s.phoneText, 'phone', '01011111111'),
      isA<PvForm>().having((s) => s.submitting, 'submitting', true),
      isA<PvForm>()
          .having((s) => s.phoneErrorKey, 'phoneError', 'authPhoneAlreadyUsed')
          .having((s) => s.phoneText, 'phone kept', '01011111111')
          .having((s) => s.submitting, 'submitting', false),
    ],
  );

  blocTest<PhoneVerificationCubit, PvState>(
    'PHONE_COUNTRY_NOT_SUPPORTED is a phone field error',
    build: () {
      repo.startError = AppFailure(
        ErrorMapper.fromCode('PHONE_COUNTRY_NOT_SUPPORTED'),
      );
      return _cubit(repo);
    },
    act: (cubit) async {
      cubit.onPhoneChanged('01012345678');
      await cubit.submit();
    },
    expect: () => [
      isA<PvForm>().having((s) => s.phoneText, 'phone', '01012345678'),
      isA<PvForm>().having((s) => s.submitting, 'submitting', true),
      isA<PvForm>().having(
        (s) => s.phoneErrorKey,
        'phoneError',
        'authPhoneCountryNotSupported',
      ),
    ],
  );

  blocTest<PhoneVerificationCubit, PvState>(
    'TERMS_CHANGED resets the checkbox and marks the changed terms',
    build: () {
      repo.startError = AppFailure(ErrorMapper.fromCode('TERMS_CHANGED'));
      return _cubit(repo, needsTerms: true);
    },
    act: (cubit) async {
      cubit
        ..onPhoneChanged('01012345678')
        ..onTermsChanged(accepted: true);
      await cubit.submit();
    },
    expect: () => [
      isA<PvForm>().having((s) => s.phoneText, 'phone', '01012345678'),
      isA<PvForm>().having((s) => s.termsAccepted, 'accepted', true),
      isA<PvForm>().having((s) => s.submitting, 'submitting', true),
      isA<PvForm>()
          .having((s) => s.termsAccepted, 'accepted', false)
          .having((s) => s.termsChanged, 'termsChanged', true),
    ],
  );

  test('PROFILE_ALREADY_COMPLETE calls onAlreadyComplete', () async {
    var refreshed = 0;
    repo.startError = AppFailure(
      ErrorMapper.fromCode('PROFILE_ALREADY_COMPLETE'),
    );
    final cubit = _cubit(
      repo,
      onAlreadyComplete: () => refreshed += 1,
    )..onPhoneChanged('01012345678');
    await cubit.submit();

    expect(refreshed, 1);
    await cubit.close();
  });

  test('a successful start carries the draft to the repository', () async {
    final cubit = _cubit(repo, needsName: true, needsTerms: true)
      ..onPhoneChanged('01012345678')
      ..onNameChanged('Mona Adel')
      ..onTermsChanged(accepted: true);
    await cubit.submit();

    expect(repo.startCalls, 1);
    expect(repo.lastPurpose, PhoneVerificationPurpose.register);
    expect(repo.lastDraft!.phone, EgyptPhone.parse('01012345678'));
    expect(repo.lastDraft!.locale, 'ar');
    await cubit.close();
  });
}

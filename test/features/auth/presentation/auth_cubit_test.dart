import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';

final class _Repository extends Mock implements AuthRepository {}

void main() {
  late _Repository repository;
  final incomplete = GuestAccount(id: 'id', phone: '+201012345678');
  final complete = GuestAccount(
    id: 'id',
    phone: '+201012345678',
    fullName: 'Guest Name',
    acceptedTermsVersion: 'v1',
  );

  setUp(() {
    repository = _Repository();
    when(
      () => repository.authStateChanges,
    ).thenAnswer((_) => const Stream.empty());
  });

  blocTest<AuthCubit, AuthState>(
    'unknown restores a signed-out session',
    build: () {
      when(() => repository.restoreSession()).thenAnswer((_) async => null);
      return AuthCubit(repository, currentTermsVersion: 'v1');
    },
    act: (cubit) => cubit.restore(),
    expect: () => [isA<SignedOut>()],
  );

  blocTest<AuthCubit, AuthState>(
    'unknown restores a signed-in session',
    build: () {
      when(() => repository.restoreSession()).thenAnswer((_) async => complete);
      return AuthCubit(repository, currentTermsVersion: 'v1');
    },
    act: (cubit) => cubit.restore(),
    expect: () => [
      isA<SignedIn>().having((s) => s.isComplete, 'complete', true),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'signed out requests a server challenge and verifies it',
    build: () {
      when(() => repository.restoreSession()).thenAnswer((_) async => null);
      when(() => repository.requestPhoneCode(any())).thenAnswer(
        (_) async => CodeChallenge(
          channel: VerificationChannel.sms,
          target: '+201012345678',
          resendAt: DateTime.utc(2026, 10, 26, 12),
        ),
      );
      when(
        () => repository.verifyPhoneCode(any(), any()),
      ).thenAnswer((_) async => incomplete);
      return AuthCubit(repository, currentTermsVersion: 'v1');
    },
    act: (cubit) async {
      await cubit.restore();
      await cubit.requestPhoneCode('+201012345678');
      await cubit.verifyPhoneCode('123456');
    },
    expect: () => [
      isA<SignedOut>(),
      isA<CodeSent>().having(
        (s) => s.challenge.resendAt,
        'server resendAt',
        DateTime.utc(2026, 10, 26, 12),
      ),
      isA<SignedIn>().having((s) => s.isComplete, 'complete', false),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'profile completion, session end, and acknowledgement',
    build: () {
      when(
        () => repository.restoreSession(),
      ).thenAnswer((_) async => incomplete);
      when(
        () => repository.completeProfile(any(), any()),
      ).thenAnswer((_) async => complete);
      return AuthCubit(repository, currentTermsVersion: 'v1');
    },
    act: (cubit) async {
      await cubit.restore();
      await cubit.completeProfile('Guest Name', 'v1');
      cubit
        ..sessionEnded('/bookings')
        ..acknowledgeSessionEnded();
    },
    expect: () => [
      isA<SignedIn>().having((s) => s.isComplete, 'complete', false),
      isA<SignedIn>().having((s) => s.isComplete, 'complete', true),
      isA<SessionEnded>().having((s) => s.returnTo, 'returnTo', '/bookings'),
      isA<SignedOut>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'server rate limit uses server deadline and resumes after it',
    build: () {
      var sends = 0;
      when(() => repository.restoreSession()).thenAnswer((_) async => null);
      when(() => repository.requestPhoneCode(any())).thenAnswer((_) async {
        if (sends++ == 1) {
          throw AuthRateLimited(DateTime.utc(2026, 10, 26, 12, 5));
        }
        return CodeChallenge(
          channel: VerificationChannel.sms,
          target: '+201012345678',
          resendAt: DateTime.utc(2026, 10, 26, 12),
        );
      });
      return AuthCubit(
        repository,
        currentTermsVersion: 'v1',
        clock: () => DateTime.utc(2026, 10, 26, 12, 6),
      );
    },
    act: (cubit) async {
      await cubit.restore();
      await cubit.requestPhoneCode('+201012345678');
      await cubit.requestPhoneCode('+201012345678');
      cubit.resumeCodeEntry();
    },
    expect: () => [
      isA<SignedOut>(),
      isA<CodeSent>(),
      isA<RateLimited>().having(
        (s) => s.until,
        'server until',
        DateTime.utc(2026, 10, 26, 12, 5),
      ),
      isA<CodeSent>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'sign out emits an in-flight state before signed out',
    build: () {
      when(() => repository.restoreSession()).thenAnswer((_) async => complete);
      when(() => repository.signOut()).thenAnswer((_) async {});
      return AuthCubit(repository, currentTermsVersion: 'v1');
    },
    act: (cubit) async {
      await cubit.restore();
      await cubit.signOut();
    },
    expect: () => [isA<SignedIn>(), isA<SigningOut>(), isA<SignedOut>()],
  );

  blocTest<AuthCubit, AuthState>(
    'rejected code stays in code entry with an error',
    build: () {
      when(() => repository.restoreSession()).thenAnswer((_) async => null);
      when(() => repository.requestPhoneCode(any())).thenAnswer(
        (_) async => CodeChallenge(
          channel: VerificationChannel.sms,
          target: '+201012345678',
          resendAt: DateTime.utc(2026),
        ),
      );
      when(
        () => repository.verifyPhoneCode(any(), any()),
      ).thenThrow(const AuthCodeRejected('OTP_INVALID'));
      return AuthCubit(repository, currentTermsVersion: 'v1');
    },
    act: (cubit) async {
      await cubit.restore();
      await cubit.requestPhoneCode('+201012345678');
      await cubit.verifyPhoneCode('000000');
    },
    expect: () => [
      isA<SignedOut>(),
      isA<CodeSent>(),
      isA<CodeSent>().having((s) => s.errorCode, 'error', 'OTP_INVALID'),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'email sign-in reaches signed-in state',
    build: () {
      when(() => repository.restoreSession()).thenAnswer((_) async => null);
      when(
        () => repository.signInEmail(any(), any()),
      ).thenAnswer((_) async => complete);
      return AuthCubit(repository, currentTermsVersion: 'v1');
    },
    act: (cubit) async {
      await cubit.restore();
      await cubit.signInEmail('guest@example.com', 'password');
    },
    expect: () => [
      isA<SignedOut>(),
      isA<SignedIn>().having((s) => s.isComplete, 'complete', true),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'recovery verification allows a new password',
    build: () {
      when(() => repository.restoreSession()).thenAnswer((_) async => null);
      when(() => repository.requestRecovery(any())).thenAnswer(
        (_) async => CodeChallenge(
          channel: VerificationChannel.emailRecovery,
          target: 'guest@example.com',
          resendAt: DateTime.utc(2026),
        ),
      );
      when(
        () => repository.verifyRecovery(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => repository.setNewPassword(any()),
      ).thenAnswer((_) async => complete);
      return AuthCubit(repository, currentTermsVersion: 'v1');
    },
    act: (cubit) async {
      await cubit.restore();
      await cubit.requestRecovery('guest@example.com');
      await cubit.verifyRecovery('123456');
      await cubit.setNewPassword('new-password');
    },
    expect: () => [
      isA<SignedOut>(),
      isA<CodeSent>(),
      isA<RecoveryVerified>(),
      isA<SignedIn>(),
    ],
  );
}

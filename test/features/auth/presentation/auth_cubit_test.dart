import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:on_air/core/auth/profile_gate.dart';
import 'package:on_air/features/account_gate/application/sign_out_service.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/domain/social_identity.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';

final class _Repository extends Mock implements AuthRepository {}

final class _SignOutCoordinator extends Mock implements SignOutCoordinator {}

void main() {
  late _Repository repository;
  final incomplete = GuestAccount(
    id: 'id',
    status: AccountStatus.incomplete,
    email: 'guest@example.com',
  );
  final complete = GuestAccount(
    id: 'id',
    status: AccountStatus.active,
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
      return AuthCubit(repository);
    },
    act: (cubit) => cubit.restore(),
    expect: () => [isA<SignedOut>()],
  );

  blocTest<AuthCubit, AuthState>(
    'unknown restores a signed-in session',
    build: () {
      when(() => repository.restoreSession()).thenAnswer((_) async => complete);
      return AuthCubit(repository);
    },
    act: (cubit) => cubit.restore(),
    expect: () => [
      isA<SignedIn>().having((s) => s.isComplete, 'complete', true),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'an incomplete restored account is signed in but not complete',
    build: () {
      when(
        () => repository.restoreSession(),
      ).thenAnswer((_) async => incomplete);
      return AuthCubit(repository);
    },
    act: (cubit) => cubit.restore(),
    expect: () => [
      isA<SignedIn>().having((s) => s.isComplete, 'complete', false),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'refreshAccount re-reads the repository and re-emits completeness',
    build: () {
      when(
        () => repository.restoreSession(),
      ).thenAnswer((_) async => incomplete);
      when(
        () => repository.refreshAccount(),
      ).thenAnswer((_) async => complete);
      return AuthCubit(repository);
    },
    act: (cubit) async {
      await cubit.restore();
      await cubit.refreshAccount();
    },
    verify: (_) {
      verify(() => repository.refreshAccount()).called(1);
    },
    expect: () => [
      isA<SignedIn>().having((s) => s.isComplete, 'complete', false),
      isA<SignedIn>().having((s) => s.isComplete, 'complete', true),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'refreshAccount emits the session end when the account is gone',
    build: () {
      when(() => repository.restoreSession()).thenAnswer((_) async => complete);
      when(() => repository.refreshAccount()).thenAnswer((_) async => null);
      return AuthCubit(repository);
    },
    act: (cubit) async {
      await cubit.restore();
      await cubit.refreshAccount();
    },
    expect: () => [isA<SignedIn>(), isA<SessionEnded>()],
  );

  test(
    'a ProfileGate event while signed in refreshes exactly once per second',
    () async {
      when(() => repository.restoreSession()).thenAnswer((_) async => complete);
      when(
        () => repository.refreshAccount(),
      ).thenAnswer((_) async => complete);
      final cubit = AuthCubit(
        repository,
        clock: () => DateTime.utc(2026, 11, 13),
      );
      addTearDown(cubit.close);
      await cubit.restore();

      ProfileGate.notify();
      ProfileGate.notify();
      await pumpEventQueue();

      verify(() => repository.refreshAccount()).called(1);
    },
  );

  test('a gate event for a signed-out guest never refreshes', () async {
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
    final cubit = AuthCubit(repository);
    addTearDown(cubit.close);
    await cubit.restore();

    ProfileGate.notify();
    await pumpEventQueue();

    verifyNever(() => repository.refreshAccount());
  });

  blocTest<AuthCubit, AuthState>(
    'sign out emits signed out only after coordinated cleanup',
    build: () {
      final coordinator = _SignOutCoordinator();
      when(() => repository.restoreSession()).thenAnswer((_) async => complete);
      when(coordinator.signOut).thenAnswer((_) async {});
      return AuthCubit(repository, signOutCoordinator: coordinator);
    },
    act: (cubit) async {
      await cubit.restore();
      await cubit.signOut();
    },
    expect: () => [isA<SignedIn>(), isA<SigningOut>(), isA<SignedOut>()],
  );

  blocTest<AuthCubit, AuthState>(
    'email sign-in reaches signed-in state',
    build: () {
      when(() => repository.restoreSession()).thenAnswer((_) async => null);
      when(
        () => repository.signInEmail(any(), any()),
      ).thenAnswer((_) async => complete);
      return AuthCubit(repository);
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
      return AuthCubit(repository);
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

  group('S005 social sign-in', () {
    final active = GuestAccount(
      id: 'social-guest',
      status: AccountStatus.active,
      phone: '+201012345678',
      email: 'social@onair.test',
      emailVerified: true,
      fullName: 'Social Guest',
    );

    blocTest<AuthCubit, AuthState>(
      'google success with an active account is complete',
      build: () {
        when(() => repository.restoreSession()).thenAnswer((_) async => null);
        when(() => repository.signInWithGoogle()).thenAnswer(
          (_) async => SocialSignInResult(account: active),
        );
        return AuthCubit(repository);
      },
      act: (cubit) async {
        await cubit.restore();
        await cubit.signInWithGoogle();
      },
      expect: () => [
        isA<SignedOut>(),
        isA<SignedIn>().having((s) => s.isComplete, 'complete', true),
      ],
      verify: (cubit) {
        expect(cubit.social.value.busy, isNull);
        expect(cubit.social.value.errorKey, isNull);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'google success with an incomplete account keeps the provider name',
      build: () {
        when(() => repository.restoreSession()).thenAnswer((_) async => null);
        when(() => repository.signInWithGoogle()).thenAnswer(
          (_) async => SocialSignInResult(
            account: GuestAccount(
              id: 'social-new',
              status: AccountStatus.incomplete,
              email: 'social@onair.test',
              emailVerified: true,
            ),
            providerFullName: 'Mona Adel',
          ),
        );
        return AuthCubit(repository);
      },
      act: (cubit) async {
        await cubit.restore();
        await cubit.signInWithGoogle();
      },
      expect: () => [
        isA<SignedOut>(),
        isA<SignedIn>().having((s) => s.isComplete, 'complete', false),
      ],
      verify: (cubit) {
        expect(cubit.providerFullName, 'Mona Adel');
        expect(cubit.social.value.busy, isNull);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'a cancelled sheet changes nothing and shows no error',
      build: () {
        when(() => repository.restoreSession()).thenAnswer((_) async => null);
        when(
          () => repository.signInWithGoogle(),
        ).thenThrow(const SocialSignInCancelled());
        return AuthCubit(repository);
      },
      act: (cubit) async {
        await cubit.restore();
        await cubit.signInWithGoogle();
      },
      expect: () => [isA<SignedOut>()],
      verify: (cubit) {
        expect(cubit.state, isA<SignedOut>());
        expect(cubit.social.value.busy, isNull);
        expect(cubit.social.value.errorKey, isNull);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'a generic failure surfaces the uniform social error',
      build: () {
        when(() => repository.restoreSession()).thenAnswer((_) async => null);
        when(
          () => repository.signInWithGoogle(),
        ).thenThrow(const AuthRequestRejected('SOCIAL_FAILED'));
        return AuthCubit(repository);
      },
      act: (cubit) async {
        await cubit.restore();
        await cubit.signInWithGoogle();
      },
      expect: () => [isA<SignedOut>()],
      verify: (cubit) {
        expect(cubit.social.value.busy, isNull);
        expect(cubit.social.value.errorKey, 'authSocialFailed');
      },
    );

    test('a second call while a sheet is in flight is ignored', () async {
      when(() => repository.restoreSession()).thenAnswer((_) async => null);
      final barrier = Completer<SocialSignInResult>();
      when(
        () => repository.signInWithGoogle(),
      ).thenAnswer((_) => barrier.future);
      final cubit = AuthCubit(repository);
      addTearDown(cubit.close);
      await cubit.restore();

      final first = cubit.signInWithGoogle();
      await cubit.signInWithGoogle();
      verify(() => repository.signInWithGoogle()).called(1);
      expect(cubit.social.value.busy, SocialProvider.google);

      barrier.complete(SocialSignInResult(account: active));
      await first;
      expect(cubit.social.value.busy, isNull);
    });

    test('sign-out clears the provider name', () async {
      final coordinator = _SignOutCoordinator();
      when(coordinator.signOut).thenAnswer((_) async {});
      when(() => repository.signInWithGoogle()).thenAnswer(
        (_) async => SocialSignInResult(
          account: GuestAccount(
            id: 'social-new',
            status: AccountStatus.incomplete,
            email: 'social@onair.test',
            emailVerified: true,
          ),
          providerFullName: 'Mona Adel',
        ),
      );
      final cubit = AuthCubit(repository, signOutCoordinator: coordinator);
      addTearDown(cubit.close);

      await cubit.signInWithGoogle();
      expect(cubit.providerFullName, 'Mona Adel');
      await cubit.signOut();
      expect(cubit.providerFullName, isNull);
    });
  });

  group('review fixes', () {
    blocTest<AuthCubit, AuthState>(
      'unconfirmed email sign-in continues on the code screen',
      build: () {
        when(() => repository.signInEmail(any(), any())).thenThrow(
          AuthVerificationRequired(
            CodeChallenge(
              channel: VerificationChannel.emailSignup,
              target: 'guest@example.com',
              resendAt: DateTime.utc(2026),
            ),
          ),
        );
        return AuthCubit(repository)..emit(const SignedOut());
      },
      act: (cubit) => cubit.signInEmail('guest@example.com', 'password1'),
      expect: () => [
        isA<CodeSent>().having(
          (s) => s.challenge.channel,
          'channel',
          VerificationChannel.emailSignup,
        ),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'a failed profile reload keeps the guest signed in',
      build: () {
        when(
          () => repository.authStateChanges,
        ).thenAnswer((_) => Stream.error(Exception('network')));
        return AuthCubit(repository)
          ..emit(SignedIn(complete, isComplete: true));
      },
      wait: const Duration(milliseconds: 10),
      expect: () => <AuthState>[],
    );

    blocTest<AuthCubit, AuthState>(
      'restore failure leaves the splash as a visitor instead of hanging',
      build: () {
        when(
          () => repository.restoreSession(),
        ).thenThrow(Exception('profile unavailable'));
        return AuthCubit(repository);
      },
      act: (cubit) => cubit.restore(),
      expect: () => [isA<SignedOut>()],
    );

    blocTest<AuthCubit, AuthState>(
      'sign-out always ends signed out, even if cleanup throws',
      build: () {
        final coordinator = _SignOutCoordinator();
        when(coordinator.signOut).thenThrow(Exception('offline'));
        return AuthCubit(repository, signOutCoordinator: coordinator)
          ..emit(SignedIn(complete, isComplete: true));
      },
      act: (cubit) async {
        try {
          await cubit.signOut();
        } on Exception {
          // The error still surfaces; the state must not be stuck.
        }
      },
      expect: () => [isA<SigningOut>(), isA<SignedOut>()],
    );
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:on_air/core/auth/profile_gate.dart';
import 'package:on_air/features/account_gate/application/sign_out_service.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
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

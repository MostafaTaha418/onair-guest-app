import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/account/domain/deletion.dart';
import 'package:on_air/features/account/presentation/delete/delete_account_cubit.dart';
import 'package:on_air/features/account_gate/application/sign_out_service.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';

class _FakeAccountRepository extends Fake implements AccountRepository {
  int requestCalls = 0;
  int sendCalls = 0;
  int confirmCalls = 0;
  DeletionBlockedException? nextRequestBlocker;
  Exception? nextRequestError;
  Exception? nextConfirmError;
  Exception? nextSendError;
  SendWindow window = SendWindow(
    serverTime: DateTime.utc(2026, 11, 17, 12),
    receivedAt: DateTime.utc(2026, 11, 17, 12),
    nextSendAt: DateTime.utc(2026, 11, 17, 12, 1),
  );

  @override
  Future<DeletionRequest> requestDeletion() async {
    requestCalls++;
    if (nextRequestBlocker case final blocker?) throw blocker;
    if (nextRequestError case final error?) throw error;
    return const DeletionRequest(
      challengeId: 'challenge-1',
      maskedEmail: 'g***@e***.com',
    );
  }

  @override
  Future<SendWindow> sendDeletionCode(String challengeId) async {
    sendCalls++;
    if (nextSendError case final error?) throw error;
    return window;
  }

  @override
  Future<void> confirmDeletion(String challengeId, String code) async {
    confirmCalls++;
    if (nextConfirmError case final error?) throw error;
  }
}

/// A concrete failure so the fake never throws a bare Object.
class _SignOutFailure implements Exception {}

class _CountingCoordinator extends Fake implements SignOutCoordinator {
  int calls = 0;
  _SignOutFailure? throws;

  @override
  Future<void> signOut() async {
    calls++;
    if (throws case final error?) throw error;
  }
}

void main() {
  late _FakeAccountRepository repository;
  late _CountingCoordinator coordinator;
  late AuthCubit auth;
  late DeleteAccountCubit cubit;

  setUpAll(() {
    registerFallbackValue(
      SendWindow(
        serverTime: DateTime.utc(2026),
        receivedAt: DateTime.utc(2026),
      ),
    );
  });

  setUp(() async {
    repository = _FakeAccountRepository();
    coordinator = _CountingCoordinator();
    final account = GuestAccount(
      id: 'id',
      status: AccountStatus.active,
      phone: '+201012345678',
      acceptedTermsVersion: 'v1',
    );
    auth = AuthCubit(
      _SignedInRepository(account),
      signOutCoordinator: coordinator,
    );
    // The deletion sign-out lands on SignedOut through this cubit, so the
    // session must be restored before the flow starts.
    await auth.restore();
    cubit = DeleteAccountCubit(repository: repository, auth: auth);
  });

  tearDown(() => cubit.close());

  test('explain starts with the checkbox off', () {
    final state = cubit.state as DeletionExplain;
    expect(state.understood, isFalse);
  });

  test('start runs request then send and lands on the code step', () async {
    cubit.setUnderstood(value: true);
    await cubit.start();
    final state = cubit.state as DeletionCodeStep;
    expect(state.challengeId, 'challenge-1');
    expect(state.maskedEmail, 'g***@e***.com');
    expect(state.window.nextSendAt, repository.window.nextSendAt);
    expect(repository.requestCalls, 1);
    expect(repository.sendCalls, 1);
    expect(auth.state, isA<SignedIn>());
  });

  test('a double tap on «احذف حسابي» sends one request and one send', () async {
    cubit.setUnderstood(value: true);
    await Future.wait([cubit.start(), cubit.start()]);
    expect(repository.requestCalls, 1);
    expect(repository.sendCalls, 1);
  });

  test(
    'the blocker refusal lands on the blocked state with the list',
    () async {
      repository.nextRequestBlocker = const DeletionBlockedException([
        DeletionBlocker(
          kind: DeletionBlockerKind.booking,
          id: 'b-1',
          code: 'OA-1',
        ),
      ]);
      cubit.setUnderstood(value: true);
      await cubit.start();
      final state = cubit.state as DeletionBlocked;
      expect(state.blockers, hasLength(1));
      expect(state.blockers.first.code, 'OA-1');
    },
  );

  test(
    'an ordinary request failure returns to explain with the error',
    () async {
      repository.nextRequestError = const AppFailure(
        ApiError(code: ErrorCode.network, messageKey: 'errorNoConnection'),
      );
      cubit.setUnderstood(value: true);
      await cubit.start();
      final state = cubit.state as DeletionExplain;
      expect(state.error, isNotNull);
      expect(state.error!.code, ErrorCode.network);
      // Retrying is possible.
      repository.nextRequestError = null;
      await cubit.start();
      expect(cubit.state, isA<DeletionCodeStep>());
    },
  );

  test('resend re-calls the send and refreshes the window', () async {
    cubit.setUnderstood(value: true);
    await cubit.start();
    repository.window = SendWindow(
      serverTime: DateTime.utc(2026, 11, 17, 13),
      receivedAt: DateTime.utc(2026, 11, 17, 13),
      nextSendAt: DateTime.utc(2026, 11, 17, 13, 1),
    );
    await cubit.resend();
    final state = cubit.state as DeletionCodeStep;
    expect(repository.sendCalls, 2);
    expect(state.window.nextSendAt, DateTime.utc(2026, 11, 17, 13, 1));
    expect(state.code, isEmpty);
  });

  test('the four OTP failures map onto the code step error', () async {
    final cases = <(ErrorCode, Exception)>[
      (
        ErrorCode.otpInvalid,
        const AppFailure(
          ApiError(code: ErrorCode.otpInvalid, messageKey: 'authOtpInvalid'),
        ),
      ),
      (
        ErrorCode.otpExpired,
        const AppFailure(
          ApiError(code: ErrorCode.otpExpired, messageKey: 'authOtpExpired'),
        ),
      ),
      (
        ErrorCode.otpAttemptsExceeded,
        const AppFailure(
          ApiError(
            code: ErrorCode.otpAttemptsExceeded,
            messageKey: 'otpAttemptsExceeded',
          ),
        ),
      ),
      (
        ErrorCode.rateLimited,
        const AppFailure(
          ApiError(code: ErrorCode.rateLimited, messageKey: 'authRateLimited'),
        ),
      ),
    ];
    cubit.setUnderstood(value: true);
    await cubit.start();
    for (final (expectedCode, error) in cases) {
      repository.nextConfirmError = error;
      cubit.updateCode(MockBackend.verificationCode);
      await cubit.confirm();
      final state = cubit.state as DeletionCodeStep;
      expect(state.error, isNotNull);
      expect(state.error!.code, expectedCode);
      expect(state.verifying, isFalse);
      repository.nextConfirmError = null;
      // The step stays for the retry.
      expect(cubit.state, isA<DeletionCodeStep>());
    }
    expect(repository.confirmCalls, cases.length);
  });

  test('confirm success signs out once and lands on deleted', () async {
    cubit.setUnderstood(value: true);
    await cubit.start();
    cubit.updateCode(MockBackend.verificationCode);
    await cubit.confirm();
    expect(coordinator.calls, 1);
    expect(cubit.state, isA<DeletionDeleted>());
    expect(auth.state, isA<SignedOut>());
  });

  test(
    'a failed sign-out still reaches deleted (the account is gone)',
    () async {
      coordinator.throws = _SignOutFailure();
      cubit.setUnderstood(value: true);
      await cubit.start();
      cubit.updateCode(MockBackend.verificationCode);
      await cubit.confirm();
      expect(coordinator.calls, 1);
      expect(cubit.state, isA<DeletionDeleted>());
      expect(auth.state, isA<SignedOut>());
    },
  );
}

/// The signed-in seam for [AuthCubit]: one account restored on session read.
final class _SignedInRepository extends Fake implements AuthRepository {
  _SignedInRepository(this.account);
  final GuestAccount account;

  @override
  Future<GuestAccount?> restoreSession() async => account;

  @override
  Stream<GuestAccount?> get authStateChanges => const Stream.empty();
}

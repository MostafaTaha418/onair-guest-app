import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/auth/profile_gate.dart';
import 'package:on_air/features/account_gate/application/sign_out_service.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/domain/social_identity.dart';

/// Sign-in-button state, kept out of [AuthState] so the social row can be
/// driven without re-emitting the whole auth state (T033).
final class SocialSignInUiState {
  const SocialSignInUiState({this.busy, this.errorKey});

  /// The provider whose native sheet is in flight; null when idle.
  final SocialProvider? busy;

  /// Localization key for the inline error above the row; null when none.
  final String? errorKey;
}

final class AuthCubit extends Cubit<AuthState> {
  AuthCubit(
    this._repository, {
    DateTime Function()? clock,
    SignOutCoordinator? signOutCoordinator,
  }) : _clock = clock ?? DateTime.now,
       _signOutCoordinator =
           signOutCoordinator ?? RepositorySignOutCoordinator(_repository),
       super(const AuthUnknown()) {
    // A failed profile reload (e.g. a network blip during token refresh) is
    // not a lost session: keep the current state. Real session ends arrive as
    // a null account or through the SessionListener's sign-out events.
    _subscription = _repository.authStateChanges.listen(
      _onExternalAccount,
      onError: (Object _, StackTrace _) {},
    );
    // The server is the gate's authority: `PROFILE_INCOMPLETE` /
    // `PHONE_NOT_VERIFIED` from any call refresh the account so the router
    // can redirect to «أكّد رقمك» (research R9).
    _gateSubscription = ProfileGate.events.listen((_) => _onProfileGate());
  }

  /// Error codes for the code screen when verification could not complete.
  static const networkError = 'NETWORK';
  static const unexpectedError = 'UNEXPECTED';

  static const _refreshDebounce = Duration(seconds: 1);

  final AuthRepository _repository;
  final DateTime Function() _clock;
  final SignOutCoordinator _signOutCoordinator;
  late final StreamSubscription<GuestAccount?> _subscription;
  late final StreamSubscription<void> _gateSubscription;
  Future<void>? _refreshFuture;
  DateTime? _lastRefreshAt;

  /// Social sign-in UI state (busy provider, error key) — see
  /// [SocialSignInUiState].
  final ValueNotifier<SocialSignInUiState> social = ValueNotifier(
    const SocialSignInUiState(),
  );

  /// The provider-supplied name for «أكّد رقمك»; memory only, cleared on
  /// sign-out.
  String? _providerFullName;
  String? get providerFullName => _providerFullName;

  Future<void> restore() async {
    GuestAccount? account;
    try {
      account = await _repository.restoreSession();
    } on Object {
      // Offline start with a stored session: leave the splash as a visitor.
      // The session stays stored; the next auth event signs the guest back in.
      account = null;
    }
    if (isClosed) return;
    emit(
      account == null
          ? const SignedOut()
          : SignedIn(account, isComplete: account.isComplete),
    );
  }

  /// Re-reads the repository and re-emits the current completeness. Concurrent
  /// callers share the in-flight future.
  Future<void> refreshAccount() {
    final inFlight = _refreshFuture;
    if (inFlight != null) return inFlight;
    _lastRefreshAt = _clock();
    final future = () async {
      try {
        final account = await _repository.refreshAccount();
        if (isClosed) return;
        if (account == null) {
          emit(const SessionEnded(null));
        } else {
          _emitAccount(account);
        }
      } on Object {
        // Same rule as restore: a failed reload keeps the session alive.
      } finally {
        _refreshFuture = null;
      }
    }();
    _refreshFuture = future;
    return future;
  }

  void _onProfileGate() {
    if (isClosed || state is! SignedIn) return;
    final last = _lastRefreshAt;
    if (last != null &&
        _clock().difference(last) < AuthCubit._refreshDebounce) {
      return;
    }
    unawaited(refreshAccount());
  }

  Future<void> signInWithGoogle() => _signInWithSocial(
    SocialProvider.google,
    _repository.signInWithGoogle,
  );

  Future<void> signInWithApple() => _signInWithSocial(
    SocialProvider.apple,
    _repository.signInWithApple,
  );

  /// One guard for both providers: while any sheet is in flight further
  /// calls are ignored, a cancelled sheet stays silent (FR-005), and any
  /// other failure surfaces as the uniform `authSocialFailed` message.
  Future<void> _signInWithSocial(
    SocialProvider provider,
    Future<SocialSignInResult> Function() action,
  ) async {
    if (social.value.busy != null) return;
    social.value = SocialSignInUiState(busy: provider);
    try {
      final result = await action();
      _providerFullName = result.providerFullName;
      _emitAccount(result.account);
    } on SocialSignInCancelled {
      // The guest closed the sheet: no message (FR-005).
    } on Object {
      social.value = const SocialSignInUiState(errorKey: 'authSocialFailed');
      return;
    } finally {
      final errorKey = social.value.errorKey;
      social.value = SocialSignInUiState(errorKey: errorKey);
    }
  }

  Future<void> requestEmailSignup(
    String name,
    String email,
    String password,
    String termsVersion, {
    String locale = 'ar',
  }) async {
    try {
      final challenge = await _repository.signUpEmail(
        name,
        email,
        password,
        termsVersion,
        locale: locale,
      );
      if (!isClosed) emit(CodeSent(challenge));
    } on AuthRateLimited catch (error) {
      if (!isClosed) {
        emit(
          RateLimited(
            CodeChallenge(
              channel: VerificationChannel.emailSignup,
              target: email.trim().toLowerCase(),
              resendAt: error.until,
            ),
            error.until,
          ),
        );
      }
    }
  }

  Future<void> verifyEmailCode(String code) async {
    final current = state;
    if (current is! CodeSent) return;
    try {
      final account = await _repository.verifyEmailCode(
        current.challenge.target,
        code,
      );
      _emitAccount(account);
    } on AuthCodeRejected catch (error) {
      if (!isClosed) emit(CodeSent(current.challenge, errorCode: error.code));
    } on AuthRateLimited catch (error) {
      if (!isClosed) emit(RateLimited(current.challenge, error.until));
    } on AuthNetworkFailure {
      if (!isClosed) emit(CodeSent(current.challenge, errorCode: networkError));
    } on Object {
      if (!isClosed) {
        emit(CodeSent(current.challenge, errorCode: unexpectedError));
      }
    }
  }

  Future<void> requestEmailVerification(String email) async {
    try {
      final challenge = await _repository.requestEmailVerification(email);
      if (!isClosed) emit(CodeSent(challenge));
    } on AuthRateLimited catch (error) {
      if (!isClosed) {
        emit(
          RateLimited(
            CodeChallenge(
              channel: VerificationChannel.emailSignup,
              target: email.trim().toLowerCase(),
              resendAt: error.until,
            ),
            error.until,
          ),
        );
      }
    }
  }

  Future<void> signInEmail(String email, String password) async {
    try {
      _emitAccount(await _repository.signInEmail(email, password));
    } on AuthVerificationRequired catch (required) {
      // Unconfirmed email (FR-027): continue on the code screen.
      if (!isClosed) emit(CodeSent(required.challenge));
    }
  }

  Future<void> requestRecovery(String email) async {
    try {
      final challenge = await _repository.requestRecovery(email);
      if (!isClosed) emit(CodeSent(challenge));
    } on AuthRateLimited catch (error) {
      if (!isClosed) {
        emit(
          RateLimited(
            CodeChallenge(
              channel: VerificationChannel.emailRecovery,
              target: email.trim().toLowerCase(),
              resendAt: error.until,
            ),
            error.until,
          ),
        );
      }
    }
  }

  Future<void> verifyRecovery(String code) async {
    final current = state;
    if (current is! CodeSent ||
        current.challenge.channel != VerificationChannel.emailRecovery) {
      return;
    }
    try {
      await _repository.verifyRecovery(current.challenge.target, code);
      if (!isClosed) emit(RecoveryVerified(current.challenge.target));
    } on AuthCodeRejected catch (error) {
      if (!isClosed) emit(CodeSent(current.challenge, errorCode: error.code));
    } on AuthRateLimited catch (error) {
      if (!isClosed) emit(RateLimited(current.challenge, error.until));
    } on AuthNetworkFailure {
      if (!isClosed) emit(CodeSent(current.challenge, errorCode: networkError));
    } on Object {
      if (!isClosed) {
        emit(CodeSent(current.challenge, errorCode: unexpectedError));
      }
    }
  }

  Future<void> setNewPassword(String password) async {
    if (state is! RecoveryVerified) return;
    _emitAccount(await _repository.setNewPassword(password));
  }

  void resumeCodeEntry() {
    final current = state;
    if (current is RateLimited && !_clock().isBefore(current.until)) {
      emit(CodeSent(current.challenge));
    }
  }

  void cancelCodeEntry() {
    if (state is CodeSent || state is RateLimited) emit(const SignedOut());
  }

  void sessionEnded(String? returnTo) {
    if (!isClosed) emit(SessionEnded(returnTo));
  }

  void acknowledgeSessionEnded() {
    if (!isClosed) emit(const SignedOut());
  }

  /// Always ends in SignedOut, even when part of the cleanup fails: the local
  /// session is removed first, so staying in SigningOut would trap the guest.
  Future<void> signOut() async {
    emit(const SigningOut());
    try {
      await _signOutCoordinator.signOut();
    } finally {
      _providerFullName = null;
      if (!isClosed) emit(const SignedOut());
    }
  }

  void _onExternalAccount(GuestAccount? account) {
    if (isClosed || state is AuthUnknown) return;
    if (account == null && state is SignedIn) {
      emit(const SessionEnded(null));
    } else if (account != null) {
      _emitAccount(account);
    }
  }

  /// Publishes an account the UI already holds — «أكّد رقمك»'s success
  /// returns the fresh profile in its `PvDone`, so the account rows update
  /// immediately and the next `refreshAccount()` only confirms (review
  /// fix 7). No network call.
  void applyAccount(GuestAccount account) => _emitAccount(account);

  void _emitAccount(GuestAccount account) {
    if (!isClosed) {
      emit(SignedIn(account, isComplete: account.isComplete));
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await _gateSubscription.cancel();
    // Harnesses may close the same cubit twice (harness + test teardown).
    if (!isClosed) {
      social.dispose();
    }
    await super.close();
  }
}

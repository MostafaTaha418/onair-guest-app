import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/features/account_gate/application/sign_out_service.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';

final class AuthCubit extends Cubit<AuthState> {
  AuthCubit(
    this._repository, {
    required this._currentTermsVersion,
    DateTime Function()? clock,
    SignOutCoordinator? signOutCoordinator,
  }) : _clock = clock ?? DateTime.now,
       _signOutCoordinator =
           signOutCoordinator ?? RepositorySignOutCoordinator(_repository),
       super(const AuthUnknown()) {
    _subscription = _repository.authStateChanges.listen(
      _onExternalAccount,
      onError: (Object _, StackTrace _) {
        if (state is SignedIn) sessionEnded(null);
      },
    );
  }

  final AuthRepository _repository;
  String _currentTermsVersion;
  final DateTime Function() _clock;
  final SignOutCoordinator _signOutCoordinator;
  late final StreamSubscription<GuestAccount?> _subscription;
  String? _pendingEmailSignupName;

  void updateTermsVersion(String version) {
    _currentTermsVersion = version;
    final current = state;
    if (current is SignedIn) _emitAccount(current.account);
  }

  Future<void> restore() async {
    final account = await _repository.restoreSession();
    if (isClosed) return;
    emit(
      account == null
          ? const SignedOut()
          : SignedIn(
              account,
              isComplete: account.isComplete(_currentTermsVersion),
            ),
    );
  }

  Future<void> requestPhoneCode(String phone) async {
    try {
      final challenge = await _repository.requestPhoneCode(phone);
      if (!isClosed) emit(CodeSent(challenge));
    } on AuthRateLimited catch (error) {
      final current = state;
      if (!isClosed && current is CodeSent) {
        emit(RateLimited(current.challenge, error.until));
      }
    }
  }

  Future<void> verifyPhoneCode(String code) async {
    final current = state;
    if (current is! CodeSent) return;
    try {
      final account = await _repository.verifyPhoneCode(
        current.challenge.target,
        code,
      );
      _emitAccount(account);
    } on AuthCodeRejected catch (error) {
      if (!isClosed) emit(CodeSent(current.challenge, errorCode: error.code));
    } on AuthRateLimited catch (error) {
      if (!isClosed) emit(RateLimited(current.challenge, error.until));
    }
  }

  void cancelCodeEntry() {
    if (state is CodeSent || state is RateLimited) emit(const SignedOut());
  }

  Future<void> requestEmailSignup(
    String name,
    String email,
    String password,
  ) async {
    _pendingEmailSignupName = name.trim();
    try {
      final challenge = await _repository.signUpEmail(name, email, password);
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
      var account = await _repository.verifyEmailCode(
        current.challenge.target,
        code,
      );
      final name = _pendingEmailSignupName;
      if (name != null && name.isNotEmpty) {
        account = await _repository.completeProfile(
          name,
          _currentTermsVersion,
        );
        _pendingEmailSignupName = null;
      }
      _emitAccount(account);
    } on AuthCodeRejected catch (error) {
      if (!isClosed) emit(CodeSent(current.challenge, errorCode: error.code));
    } on AuthRateLimited catch (error) {
      if (!isClosed) emit(RateLimited(current.challenge, error.until));
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
    _emitAccount(await _repository.signInEmail(email, password));
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

  Future<void> completeProfile(String name, String termsVersion) async {
    final account = await _repository.completeProfile(name, termsVersion);
    if (!isClosed) {
      emit(
        SignedIn(account, isComplete: account.isComplete(_currentTermsVersion)),
      );
    }
  }

  void sessionEnded(String? returnTo) {
    if (!isClosed) emit(SessionEnded(returnTo));
  }

  void acknowledgeSessionEnded() => emit(const SignedOut());

  Future<void> signOut() async {
    emit(const SigningOut());
    await _signOutCoordinator.signOut();
    if (!isClosed) emit(const SignedOut());
  }

  void _onExternalAccount(GuestAccount? account) {
    if (isClosed || state is AuthUnknown) return;
    if (account == null && state is SignedIn) {
      emit(const SessionEnded(null));
    } else if (account != null) {
      _emitAccount(account);
    }
  }

  void _emitAccount(GuestAccount account) {
    if (!isClosed) {
      emit(
        SignedIn(account, isComplete: account.isComplete(_currentTermsVersion)),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}

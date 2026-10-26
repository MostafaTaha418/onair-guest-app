import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';

final class AuthCubit extends Cubit<AuthState> {
  AuthCubit(
    this._repository, {
    required this._currentTermsVersion,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const AuthUnknown()) {
    _subscription = _repository.authStateChanges.listen(_onExternalAccount);
  }

  final AuthRepository _repository;
  String _currentTermsVersion;
  final DateTime Function() _clock;
  late final StreamSubscription<GuestAccount?> _subscription;

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
    }
  }

  Future<void> requestEmailSignup(
    String name,
    String email,
    String password,
  ) async {
    final challenge = await _repository.signUpEmail(name, email, password);
    if (!isClosed) emit(CodeSent(challenge));
  }

  Future<void> verifyEmailCode(String code) async {
    final current = state;
    if (current is! CodeSent) return;
    try {
      _emitAccount(
        await _repository.verifyEmailCode(current.challenge.target, code),
      );
    } on AuthCodeRejected catch (error) {
      if (!isClosed) emit(CodeSent(current.challenge, errorCode: error.code));
    }
  }

  Future<void> signInEmail(String email, String password) async {
    _emitAccount(await _repository.signInEmail(email, password));
  }

  Future<void> requestRecovery(String email) async {
    final challenge = await _repository.requestRecovery(email);
    if (!isClosed) emit(CodeSent(challenge));
  }

  Future<void> verifyRecovery(String code) async {
    final current = state;
    if (current is! CodeSent ||
        current.challenge.channel != VerificationChannel.emailRecovery) {
      return;
    }
    await _repository.verifyRecovery(current.challenge.target, code);
    if (!isClosed) emit(RecoveryVerified(current.challenge.target));
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
    await _repository.signOut();
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

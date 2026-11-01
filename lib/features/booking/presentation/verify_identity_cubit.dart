import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/egypt_phone.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';

sealed class VerifyIdentityState {
  const VerifyIdentityState();
}

final class VerifyChecking extends VerifyIdentityState {
  const VerifyChecking();
}

final class VerifyEmailStep extends VerifyIdentityState {
  const VerifyEmailStep({
    required this.email,
    this.error,
    this.sending = false,
    this.codeSent = false,
    this.retryAfter,
  });

  final String email;
  final ErrorCode? error;
  final bool sending;
  final bool codeSent;

  /// The remaining wait after a rate-limited send (auth deadline).
  final Duration? retryAfter;
}

final class VerifyPhoneStep extends VerifyIdentityState {
  const VerifyPhoneStep({this.error, this.sending = false});

  final ErrorCode? error;
  final bool sending;
}

final class VerifyCodeStep extends VerifyIdentityState {
  const VerifyCodeStep({
    required this.challengeId,
    this.error,
    this.verifying = false,
    this.retryAfter,
  });

  final String challengeId;
  final ErrorCode? error;
  final bool verifying;

  /// The resend window: from the challenge, or from the latest rate limit.
  final Duration? retryAfter;
}

final class VerifyDone extends VerifyIdentityState {
  const VerifyDone();
}

final class VerifyFailed extends VerifyIdentityState {
  const VerifyFailed(this.error);

  final ApiError error;
}

/// US2: stops the booking flow until the guest's email and phone are
/// confirmed. One email code covers both; the phone change is verified with
/// the same code (FR-006). Auth states are untouched — the router must not
/// leave the booking flow, so `AuthRepository` is used directly.
final class VerifyIdentityCubit extends Cubit<VerifyIdentityState> {
  VerifyIdentityCubit({required this._flow, required this._auth})
    : super(const VerifyChecking());

  final BookingFlowRepository _flow;
  final AuthRepository _auth;

  /// Lands on the first missing step (email before phone) or finishes.
  Future<void> start() async {
    emit(const VerifyChecking());
    try {
      final status = await _flow.verificationStatus();
      if (isClosed) return;
      if (!status.emailConfirmed) {
        emit(VerifyEmailStep(email: status.email ?? ''));
      } else if (!status.phoneConfirmed) {
        emit(const VerifyPhoneStep());
      } else {
        emit(const VerifyDone());
      }
    } on AppFailure catch (failure) {
      if (isClosed) return;
      emit(VerifyFailed(failure.error));
    }
  }

  Future<void> sendEmailCode() async {
    final current = state;
    if (current is! VerifyEmailStep || current.sending || current.codeSent) {
      return;
    }
    emit(VerifyEmailStep(email: current.email, sending: true));
    try {
      await _auth.requestEmailVerification(current.email);
      if (isClosed) return;
      emit(VerifyEmailStep(email: current.email, codeSent: true));
    } on Object catch (error) {
      if (isClosed) return;
      emit(
        VerifyEmailStep(
          email: current.email,
          error: _codeOf(error),
          retryAfter: _retryAfterOf(error),
        ),
      );
    }
  }

  Future<void> submitEmailCode(String code) async {
    final current = state;
    if (current is! VerifyEmailStep || current.sending) return;
    emit(VerifyEmailStep(email: current.email, codeSent: true, sending: true));
    try {
      await _auth.verifyEmailCode(current.email, code);
      await start();
    } on Object catch (error) {
      if (isClosed) return;
      emit(
        VerifyEmailStep(
          email: current.email,
          codeSent: true,
          error: _codeOf(error),
          retryAfter: _retryAfterOf(error),
        ),
      );
    }
  }

  Future<void> submitPhone(
    String raw, {
    required bool hasWhatsapp,
    String? whatsapp,
  }) async {
    final current = state;
    if (current is! VerifyPhoneStep || current.sending) return;
    final phone = EgyptPhone.tryParse(raw);
    final whatsappPhone = whatsapp == null
        ? null
        : EgyptPhone.tryParse(whatsapp);
    // Local validation first: the server is never called with a malformed
    // number.
    if (phone == null ||
        (!hasWhatsapp && whatsapp != null && whatsappPhone == null)) {
      emit(
        const VerifyPhoneStep(error: ErrorCode.phoneCountryNotSupported),
      );
      return;
    }
    emit(const VerifyPhoneStep(sending: true));
    PhoneChallenge? challenge;
    try {
      challenge = await _flow.requestPhoneChange(
        phoneE164: phone.e164,
        hasWhatsapp: hasWhatsapp,
        whatsappE164: hasWhatsapp ? null : whatsappPhone?.e164,
      );
      await _flow.sendCode(challenge.challengeId);
      if (isClosed) return;
      emit(
        VerifyCodeStep(
          challengeId: challenge.challengeId,
          retryAfter: challenge.retryAfter,
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed) return;
      if (challenge != null) {
        // The challenge exists; only sending the code failed.
        emit(
          VerifyCodeStep(
            challengeId: challenge.challengeId,
            error: failure.error.code,
            retryAfter: failure.error.retryAfter ?? challenge.retryAfter,
          ),
        );
      } else {
        emit(VerifyPhoneStep(error: failure.error.code));
      }
    }
  }

  Future<void> resendCode() async {
    final current = state;
    if (current is! VerifyCodeStep || current.verifying) return;
    try {
      await _flow.sendCode(current.challengeId);
      if (isClosed) return;
      emit(
        VerifyCodeStep(
          challengeId: current.challengeId,
          retryAfter: current.retryAfter,
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed) return;
      emit(
        VerifyCodeStep(
          challengeId: current.challengeId,
          error: failure.error.code,
          retryAfter: failure.error.retryAfter ?? current.retryAfter,
        ),
      );
    }
  }

  Future<void> submitCode(String code) async {
    final current = state;
    if (current is! VerifyCodeStep || current.verifying) return;
    emit(
      VerifyCodeStep(
        challengeId: current.challengeId,
        retryAfter: current.retryAfter,
        verifying: true,
      ),
    );
    try {
      await _flow.verifyCode(challengeId: current.challengeId, code: code);
      await start();
    } on AppFailure catch (failure) {
      if (isClosed) return;
      emit(
        VerifyCodeStep(
          challengeId: current.challengeId,
          error: failure.error.code,
          retryAfter: current.retryAfter,
        ),
      );
    }
  }

  ErrorCode _codeOf(Object error) => switch (error) {
    AppFailure(:final error) => error.code,
    AuthRateLimited() => ErrorCode.rateLimited,
    AuthCodeRejected() => ErrorCode.otpInvalid,
    AuthNetworkFailure() => ErrorCode.network,
    _ => ErrorCode.internal,
  };

  Duration? _retryAfterOf(Object error) => switch (error) {
    AppFailure(:final error) => error.retryAfter,
    AuthRateLimited(:final until) => _remaining(until),
    _ => null,
  };

  Duration? _remaining(DateTime untilUtc) {
    final seconds = untilUtc.difference(DateTime.now().toUtc()).inSeconds;
    return seconds > 0 ? Duration(seconds: seconds) : null;
  }
}

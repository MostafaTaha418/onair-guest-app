import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
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

/// The phone is not confirmed: the screen shows the WhatsApp redirect card
/// (S005 US6) — no booking-flow phone challenge any more.
final class VerifyPhoneStep extends VerifyIdentityState {
  const VerifyPhoneStep();
}

final class VerifyDone extends VerifyIdentityState {
  const VerifyDone();
}

final class VerifyFailed extends VerifyIdentityState {
  const VerifyFailed(this.error);

  final ApiError error;
}

/// US2: stops the booking flow until the guest's email is confirmed and the
/// phone is on the account (S005 US6 hands the phone to «أكّد رقمك»). Auth
/// states are untouched — the router must not leave the booking flow, so
/// `AuthRepository` is used directly.
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

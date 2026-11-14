import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/auth/domain/egypt_phone.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';

sealed class PvState {
  const PvState();
}

/// The «أكّد رقمك» form step: number, plus name and terms only when the
/// account misses them (data-model §4).
final class PvForm extends PvState {
  const PvForm({
    this.phoneText = '',
    this.nameText = '',
    this.termsAccepted = false,
    this.termsChanged = false,
    this.submitting = false,
    this.phoneErrorKey,
    this.nameErrorKey,
    this.generalErrorKey,
    this.generalErrorRequestId,
  });

  final String phoneText;
  final String nameText;
  final bool termsAccepted;

  /// The server reported `TERMS_CHANGED`: the checkbox was reset and the
  /// fresh terms must be accepted again (FR-017).
  final bool termsChanged;
  final bool submitting;
  final String? phoneErrorKey;
  final String? nameErrorKey;
  final String? generalErrorKey;

  /// The server reference for [generalErrorKey] (Constitution VIII).
  final String? generalErrorRequestId;

  PvForm copyWith({
    String? phoneText,
    String? nameText,
    bool? termsAccepted,
    bool? termsChanged,
    bool? submitting,
    String? phoneErrorKey,
    String? nameErrorKey,
    String? generalErrorKey,
    String? generalErrorRequestId,
    bool clearPhoneError = false,
    bool clearNameError = false,
    bool clearGeneralError = false,
  }) => PvForm(
    phoneText: phoneText ?? this.phoneText,
    nameText: nameText ?? this.nameText,
    termsAccepted: termsAccepted ?? this.termsAccepted,
    termsChanged: termsChanged ?? this.termsChanged,
    submitting: submitting ?? this.submitting,
    phoneErrorKey: clearPhoneError ? null : phoneErrorKey ?? this.phoneErrorKey,
    nameErrorKey: clearNameError ? null : nameErrorKey ?? this.nameErrorKey,
    generalErrorKey: clearGeneralError
        ? null
        : generalErrorKey ?? this.generalErrorKey,
    generalErrorRequestId: clearGeneralError
        ? null
        : generalErrorRequestId ?? this.generalErrorRequestId,
  );
}

/// The WhatsApp code step (data-model §4): the server challenge, the entered
/// code and the delivery notices. `codeFieldEnabled` goes false after
/// `OTP_ATTEMPTS_EXCEEDED` until a fresh code arrives (FR-018).
final class PvCode extends PvState {
  const PvCode({
    required this.challenge,
    this.code = '',
    this.verifying = false,
    this.resending = false,
    this.codeFieldEnabled = true,
    this.errorKey,
    this.errorRequestId,
    this.notice,
  });

  final WhatsAppChallenge challenge;
  final String code;
  final bool verifying;
  final bool resending;
  final bool codeFieldEnabled;
  final String? errorKey;

  /// The server reference for [errorKey] (Constitution VIII).
  final String? errorRequestId;

  /// notOnWhatsApp / attestationFailed / temporarilyUnavailable; set from
  /// the delivery poll or the send errors.
  final PvNotice? notice;

  PvCode copyWith({
    WhatsAppChallenge? challenge,
    String? code,
    bool? verifying,
    bool? resending,
    bool? codeFieldEnabled,
    String? errorKey,
    String? errorRequestId,
    PvNotice? notice,
    bool clearError = false,
    bool clearNotice = false,
  }) => PvCode(
    challenge: challenge ?? this.challenge,
    code: code ?? this.code,
    verifying: verifying ?? this.verifying,
    resending: resending ?? this.resending,
    codeFieldEnabled: codeFieldEnabled ?? this.codeFieldEnabled,
    errorKey: clearError ? null : errorKey ?? this.errorKey,
    errorRequestId: clearError ? null : errorRequestId ?? this.errorRequestId,
    notice: clearNotice ? null : notice ?? this.notice,
  );
}

enum PvNotice {
  /// The delivery poll answered `failed/not_on_whatsapp`.
  notOnWhatsApp,

  /// `APP_ATTESTATION_FAILED` from the send.
  attestationFailed,

  /// `OTP_TEMPORARILY_UNAVAILABLE` from the send.
  temporarilyUnavailable,
}

/// The number was confirmed: `register` → the account is active and the
/// router releases the guest to `from`; `change` → pop + snackbar.
final class PvDone extends PvState {
  const PvDone({required this.account, required this.purpose});

  final GuestAccount account;
  final PhoneVerificationPurpose purpose;
}

/// `OTP_SEND_BLOCKED` (§4.3): the server paused every send until
/// [blockedUntil]. `code` keeps the code-step snapshot the block
/// interrupted, `form` the form-step one — both render disabled behind the
/// `BlockedNotice`.
final class PvBlocked extends PvState {
  const PvBlocked({
    required this.blockedUntil,
    required this.serverTime,
    this.code,
    this.form,
  });

  final DateTime blockedUntil;
  final DateTime serverTime;
  final PvCode? code;
  final PvForm? form;
}

/// Screen-scoped (Constitution: state management): one cubit per
/// «أكّد رقمك» / change-number screen. It keeps no static state, writes
/// nothing to storage, and `close()` cancels the polling timer.
final class PhoneVerificationCubit extends Cubit<PvState> {
  PhoneVerificationCubit(
    this._repository, {
    required this.purpose,
    required this.needsName,
    required this.needsTerms,
    required this.locale,
    required this._currentTermsVersion,
    this.prefilledName,
    this.onAlreadyComplete,
    this.onRegistered,
    this.onChanged,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(PvForm(nameText: prefilledName ?? ''));

  static const _pollInterval = Duration(seconds: 5);
  static const _maxPollTicks = 12;

  final PhoneVerificationRepository _repository;
  final PhoneVerificationPurpose purpose;

  /// Only when the account has no name (register).
  final bool needsName;

  /// Only when the account has no accepted terms (register).
  final bool needsTerms;
  final String locale;
  final String? prefilledName;
  final DateTime Function() _clock;

  /// The profile is already active (`PROFILE_ALREADY_COMPLETE`): the screen
  /// refreshes the account so the router can release the guest.
  final VoidCallback? onAlreadyComplete;

  /// `register` success: the screen refreshes the account (T056).
  final VoidCallback? onRegistered;

  /// `change` success: the screen pops with `true`.
  final VoidCallback? onChanged;

  String? _currentTermsVersion;
  bool _submitInFlight = false;
  Timer? _pollTimer;
  int _pollTicks = 0;

  // The draft the form step held, restored by «تعديل الرقم» and by
  // PHONE_ALREADY_USED (FR-020, FR-023).
  String? _draftPhoneText;
  String? _draftNameText;
  bool _draftTermsAccepted = false;

  /// The screen feeds the freshly loaded app-config version (T046).
  String? get termsVersion => _currentTermsVersion;

  set termsVersion(String version) {
    _currentTermsVersion = version;
  }

  void onPhoneChanged(String text) => emit(
    _form(
      (f) => f.copyWith(
        phoneText: text,
        clearPhoneError: true,
        clearGeneralError: true,
      ),
    ),
  );

  void onNameChanged(String text) => emit(
    _form(
      (f) => f.copyWith(
        nameText: text,
        clearNameError: true,
        clearGeneralError: true,
      ),
    ),
  );

  void onTermsChanged({required bool accepted}) => emit(
    _form(
      (f) => f.copyWith(
        termsAccepted: accepted,
        termsChanged: false,
        clearGeneralError: true,
      ),
    ),
  );

  /// The «متابعة» gate: a valid Egyptian number, plus a name and accepted
  /// terms when the account misses them.
  bool get isFormValid {
    final form = state;
    if (form is! PvForm) return false;
    if (EgyptPhone.tryParse(form.phoneText) == null) return false;
    if (needsName) {
      final name = form.nameText.trim();
      if (name.length < 2 || name.length > 80) return false;
    }
    // Accepting terms without the SERVER's version is meaningless: the
    // config must have loaded (review fix 9).
    if (needsTerms && (_currentTermsVersion == null || !form.termsAccepted)) {
      return false;
    }
    return true;
  }

  Future<void> submit() async {
    final form = state;
    if (form is! PvForm || form.submitting || _submitInFlight) return;

    // Local validation first: an invalid form never reaches the server.
    String? phoneErrorKey;
    String? nameErrorKey;
    final phone = EgyptPhone.tryParse(form.phoneText);
    if (phone == null) {
      phoneErrorKey = form.phoneText.trim().isEmpty
          ? 'authFieldRequired'
          : 'authPhoneInvalid';
    }
    if (needsName) {
      final name = form.nameText.trim();
      if (name.isEmpty) {
        nameErrorKey = 'authFieldRequired';
      } else if (name.length < 2 || name.length > 80) {
        nameErrorKey = 'authNameInvalid';
      }
    }
    if (phoneErrorKey != null ||
        nameErrorKey != null ||
        (needsTerms && !form.termsAccepted)) {
      emit(
        form.copyWith(
          submitting: false,
          phoneErrorKey: phoneErrorKey,
          nameErrorKey: nameErrorKey,
        ),
      );
      return;
    }

    _submitInFlight = true;
    _draftPhoneText = form.phoneText;
    _draftNameText = form.nameText;
    _draftTermsAccepted = form.termsAccepted;
    emit(form.copyWith(submitting: true, clearGeneralError: true));
    try {
      final challengeId = await _repository.start(
        PhoneVerificationDraft(
          phone: phone!,
          fullName: needsName ? form.nameText.trim() : null,
          acceptedTermsVersion: needsTerms ? _currentTermsVersion : null,
          locale: locale,
        ),
        purpose,
      );
      if (isClosed) return;
      await _send(challengeId, phone: phone);
    } on AppFailure catch (error) {
      if (isClosed) return;
      _mapStartFailure(error);
    } on Object {
      // A surprise from the repository layer must never leave the button
      // spinning (review fix 4).
      if (isClosed) return;
      final current = state;
      if (current is! PvForm) return;
      emit(
        current.copyWith(
          submitting: false,
          generalErrorKey: 'errorUnexpectedNoRef',
        ),
      );
    } finally {
      _submitInFlight = false;
    }
  }

  /// Sends the code for an open challenge (also the «ابعت كود جديد» path).
  Future<void> _send(String challengeId, {EgyptPhone? phone}) async {
    try {
      final challenge = await _repository.send(challengeId);
      if (isClosed) return;
      emit(PvCode(challenge: challenge));
      _startPolling(challenge.challengeId);
    } on AppFailure catch (error) {
      if (isClosed) return;
      if (state is PvCode) {
        // A failed resend keeps the code step and shows the reason.
        _mapSendFailure(error);
        return;
      }
      // The FIRST send can already be rate-limited: the server window rides
      // the error payload, so the code step renders for the SAME challenge —
      // no new start() and no lost wait (review fix 5).
      final nextSendAt = _detailsTime(error.error.details, 'next_send_at');
      if (error.error.code == ErrorCode.rateLimited &&
          nextSendAt != null &&
          phone != null) {
        final serverTime =
            _detailsTime(error.error.details, 'server_time') ?? _clock();
        emit(
          PvCode(
            challenge: WhatsAppChallenge(
              challengeId: challengeId,
              maskedPhone: maskPhone(phone.e164),
              expiresAt: serverTime,
              window: SendWindow(
                serverTime: serverTime,
                receivedAt: _clock(),
                nextSendAt: nextSendAt,
              ),
            ),
          ),
        );
        _startPolling(challengeId);
        return;
      }
      _mapStartFailure(error);
    }
  }

  void _startPolling(String challengeId) {
    _pollTimer?.cancel();
    _pollTicks = 0;
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll(challengeId));
  }

  Future<void> _poll(String challengeId) async {
    final current = state;
    if (current is! PvCode || current.verifying || current.resending) return;
    _pollTicks += 1;
    if (_pollTicks > _maxPollTicks) {
      _pollTimer?.cancel();
      return;
    }
    final tick = _pollTicks;
    try {
      final (status, failure, window) = await _repository.status(challengeId);
      if (isClosed) return;
      final latest = state;
      if (latest is! PvCode) return;
      final challenge = WhatsAppChallenge(
        challengeId: latest.challenge.challengeId,
        maskedPhone: latest.challenge.maskedPhone,
        expiresAt: latest.challenge.expiresAt,
        window: window,
      );
      switch (status) {
        case DeliveryStatus.delivered || DeliveryStatus.read:
          // Delivered: stop quietly (R7).
          _pollTimer?.cancel();
          emit(latest.copyWith(challenge: challenge));
        case DeliveryStatus.failed:
          _pollTimer?.cancel();
          emit(
            latest.copyWith(
              challenge: challenge,
              notice: failure == DeliveryFailure.notOnWhatsApp
                  ? PvNotice.notOnWhatsApp
                  : latest.notice,
            ),
          );
        case DeliveryStatus.pending ||
            DeliveryStatus.sent ||
            DeliveryStatus.unknown:
          // Still travelling: the periodic timer re-fires unless the budget
          // ran out.
          if (tick >= _maxPollTicks) {
            _pollTimer?.cancel();
          }
          emit(latest.copyWith(challenge: challenge));
      }
    } on AppFailure {
      // A failed status poll is not fatal: the guest can still type the
      // code; the next tick retries until the budget runs out.
    }
  }

  void onCodeChanged(String text) {
    final current = state;
    if (current is! PvCode) return;
    emit(current.copyWith(code: text, clearError: true));
  }

  Future<void> verify() async {
    final current = state;
    if (current is! PvCode ||
        current.verifying ||
        current.resending ||
        !current.codeFieldEnabled ||
        current.code.length != 6) {
      return;
    }
    _pollTimer?.cancel();
    emit(current.copyWith(verifying: true, clearError: true));
    try {
      final account = await _repository.verify(
        current.challenge.challengeId,
        current.code,
      );
      if (isClosed) return;
      emit(PvDone(account: account, purpose: purpose));
      switch (purpose) {
        case PhoneVerificationPurpose.register:
          onRegistered?.call();
        case PhoneVerificationPurpose.change:
          onChanged?.call();
      }
    } on AppFailure catch (error) {
      if (isClosed) return;
      final latest = state;
      final codeState = latest is PvCode
          ? latest
          : PvCode(challenge: current.challenge);
      final code = error.error.code;
      if (code == ErrorCode.otpInvalid) {
        emit(codeState.copyWith(verifying: false, errorKey: 'authOtpInvalid'));
      } else if (code == ErrorCode.otpExpired) {
        emit(codeState.copyWith(verifying: false, errorKey: 'authOtpExpired'));
      } else if (code == ErrorCode.otpSuperseded) {
        emit(
          codeState.copyWith(
            verifying: false,
            errorKey: 'whatsappUseLatestCode',
          ),
        );
      } else if (code == ErrorCode.otpAttemptsExceeded) {
        emit(
          codeState.copyWith(
            verifying: false,
            codeFieldEnabled: false,
            errorKey: 'otpAttemptsExceeded',
          ),
        );
      } else if (code == ErrorCode.phoneAlreadyUsed) {
        // The number went to another account while we confirmed (FR-023):
        // back to the form with the draft and the field error.
        emit(
          PvForm(
            phoneText: _draftPhoneText ?? '',
            nameText: _draftNameText ?? '',
            termsAccepted: _draftTermsAccepted,
            phoneErrorKey: 'authPhoneAlreadyUsed',
          ),
        );
      } else {
        emit(
          codeState.copyWith(
            verifying: false,
            errorKey: error.error.messageKey,
            errorRequestId: error.error.requestId,
          ),
        );
      }
    } on Object {
      if (isClosed) return;
      final latest = state;
      final codeState = latest is PvCode
          ? latest
          : PvCode(challenge: current.challenge);
      emit(
        codeState.copyWith(verifying: false, errorKey: 'errorUnexpectedNoRef'),
      );
    }
  }

  /// «تعديل الرقم»: back to the form step with the previous draft (FR-020).
  void editNumber() {
    final current = state;
    if (current is! PvCode) return;
    _pollTimer?.cancel();
    emit(
      PvForm(
        phoneText: _draftPhoneText ?? '',
        nameText: _draftNameText ?? '',
        termsAccepted: _draftTermsAccepted,
      ),
    );
  }

  /// «ابعت كود جديد»: rotates the code on the same challenge. The window
  /// rendering (countdown, block) completes in US5 (T063/T064).
  Future<void> resend() async {
    final current = state;
    if (current is! PvCode || current.resending || current.verifying) return;
    _pollTimer?.cancel();
    emit(current.copyWith(resending: true, clearError: true));
    try {
      final challenge = await _repository.send(current.challenge.challengeId);
      if (isClosed) return;
      final latest = state;
      final codeState = latest is PvCode ? latest : current;
      emit(
        codeState.copyWith(
          challenge: challenge,
          resending: false,
          codeFieldEnabled: true,
          code: '',
          clearNotice: true,
        ),
      );
      _startPolling(challenge.challengeId);
    } on AppFailure catch (error) {
      if (isClosed) return;
      _mapSendFailure(error);
    } on Object {
      // A surprise from the repository layer must never leave the button
      // spinning (review fix 4).
      if (isClosed) return;
      final latest = state;
      if (latest is! PvCode) return;
      emit(
        latest.copyWith(resending: false, errorKey: 'errorUnexpectedNoRef'),
      );
    }
  }

  void _mapSendFailure(AppFailure failure) {
    final current = state;
    final codeState = current is PvCode
        ? current
        : PvCode(
            challenge: WhatsAppChallenge(
              challengeId: '',
              maskedPhone: '',
              expiresAt: _clock(),
              window: SendWindow(serverTime: _clock(), receivedAt: _clock()),
            ),
          );
    final code = failure.error.code;
    if (code == ErrorCode.appAttestationFailed) {
      emit(
        codeState.copyWith(
          resending: false,
          notice: PvNotice.attestationFailed,
        ),
      );
    } else if (code == ErrorCode.otpTemporarilyUnavailable) {
      emit(
        codeState.copyWith(
          resending: false,
          notice: PvNotice.temporarilyUnavailable,
        ),
      );
    } else if (code == ErrorCode.otpSendBlocked) {
      _emitBlocked(failure, code: codeState);
    } else if (code == ErrorCode.rateLimited) {
      // The server's `next_send_at` decides the wait (R8): the window
      // refreshes from the error payload, no error text.
      final nextSendAt = _detailsTime(failure.error.details, 'next_send_at');
      if (nextSendAt == null) {
        emit(
          codeState.copyWith(
            resending: false,
            errorKey: failure.error.messageKey,
            errorRequestId: failure.error.requestId,
          ),
        );
        return;
      }
      emit(
        codeState.copyWith(
          resending: false,
          challenge: codeState.challenge.withWindow(
            SendWindow(
              serverTime:
                  _detailsTime(failure.error.details, 'server_time') ??
                  _clock(),
              receivedAt: _clock(),
              nextSendAt: nextSendAt,
            ),
          ),
        ),
      );
    } else {
      emit(
        codeState.copyWith(
          resending: false,
          errorKey: failure.error.messageKey,
          errorRequestId: failure.error.requestId,
        ),
      );
    }
  }

  /// `OTP_SEND_BLOCKED` from either step: the block notice replaces the
  /// error text; the interrupted step renders disabled behind it (T064).
  void _emitBlocked(AppFailure failure, {PvCode? code, PvForm? form}) {
    final blockedUntil = _detailsTime(failure.error.details, 'blocked_until');
    if (blockedUntil == null) {
      // A block without a date cannot be rendered from the server data
      // (Constitution II) — the generic error text stands in.
      final current = state;
      if (current is PvCode) {
        emit(
          current.copyWith(resending: false, errorKey: 'otpBlockedUntil'),
        );
      } else if (current is PvForm) {
        emit(
          current.copyWith(
            submitting: false,
            generalErrorKey: 'otpBlockedUntil',
          ),
        );
      }
      return;
    }
    emit(
      PvBlocked(
        blockedUntil: blockedUntil,
        serverTime:
            _detailsTime(failure.error.details, 'server_time') ?? _clock(),
        code: code,
        form: form,
      ),
    );
  }

  void _mapStartFailure(AppFailure failure) {
    final form = state as PvForm;
    final code = failure.error.code;
    if (code == ErrorCode.phoneAlreadyUsed) {
      emit(
        form.copyWith(submitting: false, phoneErrorKey: 'authPhoneAlreadyUsed'),
      );
    } else if (code == ErrorCode.phoneCountryNotSupported) {
      emit(
        form.copyWith(
          submitting: false,
          phoneErrorKey: 'authPhoneCountryNotSupported',
        ),
      );
    } else if (code == ErrorCode.termsChanged) {
      emit(
        form.copyWith(
          submitting: false,
          termsAccepted: false,
          termsChanged: true,
        ),
      );
    } else if (code == ErrorCode.profileAlreadyComplete) {
      emit(form.copyWith(submitting: false));
      onAlreadyComplete?.call();
    } else if (code == ErrorCode.otpSendBlocked) {
      // The first send can already be blocked (a device key from an older
      // account, quickstart V5): the notice shows on the form step (T064).
      _emitBlocked(failure, form: form.copyWith(submitting: false));
    } else {
      emit(
        form.copyWith(
          submitting: false,
          generalErrorKey: failure.error.messageKey,
          generalErrorRequestId: failure.error.requestId,
        ),
      );
    }
  }

  PvForm _form(PvForm Function(PvForm) transform) {
    final current = state;
    return current is PvForm ? transform(current) : const PvForm();
  }

  /// The A8 error payload: ISO timestamps riding on `ApiError.details`
  /// (`next_send_at`, `blocked_until`, `server_time`).
  static DateTime? _detailsTime(Map<String, dynamic>? details, String field) {
    final value = details?[field];
    return value == null ? null : DateTime.parse(value as String).toUtc();
  }

  @override
  Future<void> close() async {
    _pollTimer?.cancel();
    await super.close();
  }
}

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
/// account misses them (data-model §4). The code step states arrive with
/// US4.
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

  PvForm copyWith({
    String? phoneText,
    String? nameText,
    bool? termsAccepted,
    bool? termsChanged,
    bool? submitting,
    String? phoneErrorKey,
    String? nameErrorKey,
    String? generalErrorKey,
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
  );
}

/// The number was confirmed: `register` → the account is active and the
/// router releases the guest to `from`; `change` → pop + snackbar.
final class PvDone extends PvState {
  const PvDone({required this.account, required this.purpose});

  final GuestAccount account;
  final PhoneVerificationPurpose purpose;
}

/// Screen-scoped (Constitution: state management): one cubit per
/// «أكّد رقمك» / change-number screen. It keeps no static state and writes
/// nothing to storage.
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
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(PvForm(nameText: prefilledName ?? ''));

  final PhoneVerificationRepository _repository;
  final PhoneVerificationPurpose purpose;

  /// Only when the account has no name (register).
  final bool needsName;

  /// Only when the account has no accepted terms (register).
  final bool needsTerms;
  final String? prefilledName;
  final String locale;

  /// Injectable clock for the US4 countdowns and polling.
  // ignore: unused_field
  final DateTime Function() _clock;

  /// The profile is already active (`PROFILE_ALREADY_COMPLETE`): the screen
  /// refreshes the account so the router can release the guest.
  final VoidCallback? onAlreadyComplete;

  String? _currentTermsVersion;

  bool _submitInFlight = false;

  /// The screen feeds the freshly loaded app-config version (T046).
  /// The accepted terms version the draft carries when the account needs
  /// to accept the current one.
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
    if (needsTerms && !form.termsAccepted) return false;
    return true;
  }

  Future<void> submit() async {
    final form = state as PvForm;
    if (form.submitting || _submitInFlight) return;

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
    emit(form.copyWith(submitting: true, clearGeneralError: true));
    try {
      await _repository.start(
        PhoneVerificationDraft(
          phone: phone!,
          fullName: needsName ? form.nameText.trim() : null,
          acceptedTermsVersion: needsTerms ? _currentTermsVersion : null,
          locale: locale,
        ),
        purpose,
      );
      if (isClosed) return;
      // The WhatsApp code step continues in US4 (start → send → PvCode);
      // until then the form simply returns to its idle state.
      emit(
        PvForm(
          phoneText: form.phoneText,
          nameText: form.nameText,
          termsAccepted: form.termsAccepted,
        ),
      );
    } on AppFailure catch (error) {
      if (isClosed) return;
      _mapStartFailure(error);
    } finally {
      _submitInFlight = false;
    }
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
    } else {
      emit(
        form.copyWith(
          submitting: false,
          generalErrorKey: failure.error.messageKey,
        ),
      );
    }
  }

  PvForm _form(PvForm Function(PvForm) transform) {
    final current = state;
    return current is PvForm ? transform(current) : const PvForm();
  }
}

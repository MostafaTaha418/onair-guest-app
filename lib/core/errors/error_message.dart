import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The user-facing message for an [ApiError].
///
/// Only a handful of codes deserve their own sentence; everything else is an
/// unexpected error whose reference number `ErrorView` renders separately.
String apiErrorMessage(ApiError error, AppLocalizations l10n) =>
    switch (error.code) {
      ErrorCode.network => l10n.errorNoConnection,
      ErrorCode.notFound ||
      ErrorCode.propertyNotAvailable => l10n.propertyNotAvailable,
      ErrorCode.validationFailed => l10n.errorValidationFailed,
      _ => l10n.errorUnexpectedNoRef,
    };

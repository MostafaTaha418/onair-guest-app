import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The «أكّد رقمك» steps render their failure inline, with no `ErrorView`
/// beside it, so an unexpected server error carries its reference number in
/// the sentence itself (Constitution VIII). Everything else is the shared
/// [apiErrorMessage].
String phoneVerificationErrorText(ApiError error, AppLocalizations l10n) {
  final requestId = error.requestId;
  if (error.code == ErrorCode.internal && requestId != null) {
    return l10n.errorUnexpected(requestId);
  }
  return apiErrorMessage(error, l10n);
}

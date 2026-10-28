import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Turns any failure from an auth request into a plain Arabic message
/// (FR-011, FR-029, FR-039). Raw server text is never shown.
///
/// [now] is injectable for tests; wait times come from the server deadline.
String authErrorMessage(
  Object error,
  AppLocalizations l10n, {
  DateTime Function() now = DateTime.now,
}) => switch (error) {
  AuthRateLimited(:final until) => l10n.authRateLimited(
    l10n.authWaitSeconds(
      until.difference(now().toUtc()).inSeconds.clamp(1, 86400),
    ),
  ),
  AuthNetworkFailure() => l10n.errorNoConnection,
  AuthRequestRejected(code: 'INVALID_CREDENTIALS') =>
    l10n.authInvalidCredentials,
  AuthRequestRejected(code: 'PHONE_COUNTRY_NOT_SUPPORTED') =>
    l10n.authPhoneCountryNotSupported,
  _ => l10n.errorUnexpectedNoRef,
};

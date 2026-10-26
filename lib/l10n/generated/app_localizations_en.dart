// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'OnAir';

  @override
  String get home => 'Home';

  @override
  String get search => 'Search';

  @override
  String get bookings => 'My bookings';

  @override
  String get favorites => 'Favorites';

  @override
  String get account => 'My account';

  @override
  String get welcome => 'Welcome';

  @override
  String get seeAll => 'See all';

  @override
  String get retry => 'Retry';

  @override
  String get emptyState => 'Nothing to show yet.';

  @override
  String get loading => 'Loading';

  @override
  String get offline => 'No internet connection.';

  @override
  String referenceNumber(String ref) {
    return 'Reference: $ref';
  }

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get verificationCode => 'Verification code';

  @override
  String get sendCode => 'Send code';

  @override
  String get confirm => 'Confirm';

  @override
  String get fullName => 'Full name';

  @override
  String get errorUnauthenticated => 'Your session ended. Sign in again.';

  @override
  String get authPhoneCountryNotSupported =>
      'Only Egyptian mobile numbers are supported. You can sign up with email.';

  @override
  String get authOtpInvalid =>
      'That code is incorrect. Check the message and try again.';

  @override
  String get authOtpExpired => 'That code expired. Request a new one.';

  @override
  String authRateLimited(String time) {
    return 'Too many attempts. Try again after $time.';
  }

  @override
  String get errorValidationFailed => 'Check the information you entered.';

  @override
  String get authTermsChanged =>
      'The terms changed. Review and accept them to continue.';

  @override
  String get authProfileIncomplete => 'Complete your profile to continue.';

  @override
  String get appUpdateRequired => 'Update the app to continue.';

  @override
  String get bookingPhoneNotVerified => 'Verify your phone before booking.';

  @override
  String get bookingEmailNotVerified => 'Verify your email before booking.';

  @override
  String get bookingDatesUnavailable => 'Those dates are unavailable.';

  @override
  String get bookingGuestsExceeded => 'Too many guests for this property.';

  @override
  String get bookingQuoteExpired =>
      'The price changed. Review your summary again.';

  @override
  String get propertyNotAvailable => 'This property is currently unavailable.';

  @override
  String get errorActionNotAllowed => 'This action is unavailable right now.';

  @override
  String get stayCollectorNotAuthorized =>
      'The collector is not authorized. Contact support.';

  @override
  String errorUnexpected(String ref) {
    return 'Something went wrong. Reference: $ref';
  }

  @override
  String get errorNoConnection => 'No internet connection.';

  @override
  String get errorCancelled => 'The operation was cancelled.';

  @override
  String get authInvalidCredentials => 'Incorrect email or password.';

  @override
  String get authCodeSent => 'We sent a verification code.';

  @override
  String get authRecoverySent =>
      'If the email is registered, you will receive recovery instructions.';

  @override
  String get notifications => 'Notifications';

  @override
  String get notAvailable => 'Not available yet';

  @override
  String get searchEmpty => 'Start looking for your next stay.';

  @override
  String get bookingsEmpty => 'Your bookings will appear here.';

  @override
  String get favoritesEmpty => 'Your saved places will appear here.';

  @override
  String get accountEmpty => 'Your account details will appear here.';
}

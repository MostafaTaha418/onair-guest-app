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
  String get errorUnexpectedNoRef =>
      'Something unexpected happened. Please try again.';

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

  @override
  String get authLoginTitle => 'Welcome to OnAir';

  @override
  String get authRegisterTitle => 'Create your account';

  @override
  String get authPhoneHint => 'Example: 01012345678';

  @override
  String get authPhoneInvalid =>
      'Enter a valid 11-digit Egyptian mobile number.';

  @override
  String get authPhoneTab => 'Phone';

  @override
  String get authEmailTab => 'Email';

  @override
  String get authEmailComingSoon => 'Email sign-up is coming soon.';

  @override
  String get authTermsPrefix => 'By continuing, you agree to the';

  @override
  String get terms => 'Terms and conditions';

  @override
  String get privacy => 'Privacy policy';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authHasAccount => 'Already have an account?';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authCodeTitle => 'Enter the verification code';

  @override
  String authCodeDescription(String phone) {
    return 'We sent a 6-digit code to $phone';
  }

  @override
  String get authResend => 'Resend code';

  @override
  String authResendIn(String time) {
    return 'Resend in $time';
  }

  @override
  String get authChangePhone => 'Change phone number';

  @override
  String get authCompleteProfileTitle => 'Complete your profile';

  @override
  String get authNameInvalid => 'Name must be between 2 and 80 characters.';

  @override
  String get authAcceptTerms => 'I agree to the terms and privacy policy';

  @override
  String get authTermsRequired => 'Accept the terms to continue.';

  @override
  String authWaitSeconds(int seconds) {
    return '$seconds seconds';
  }

  @override
  String get authEmailInvalid => 'Enter a valid email address.';

  @override
  String get authPasswordRule =>
      'At least 8 characters with a letter and a number';

  @override
  String get authPasswordWeak => 'Weak';

  @override
  String get authPasswordMedium => 'Medium';

  @override
  String get authPasswordStrong => 'Strong';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authRecoveryTitle => 'Recover your password';

  @override
  String get authRecoveryDescription =>
      'Enter your email and we will send a recovery code.';

  @override
  String get authNewPasswordTitle => 'New password';

  @override
  String get authNewPassword => 'Save password';

  @override
  String get authChangeEmail => 'Change email';

  @override
  String get authEmailNotVerified => 'Not verified';

  @override
  String get authVerifyNow => 'Verify now';

  @override
  String get authEmailStatus => 'Email status';

  @override
  String get authSignUpWithEmail => 'Create account with email';

  @override
  String get authSignInWithEmail => 'Sign in with email';

  @override
  String get authClose => 'Close';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredStoreButton => 'Update the app';

  @override
  String get homeHello => 'Hello';

  @override
  String get homeSearchHint => 'Find a place: where, when, who';

  @override
  String get homeAreasTitle => 'Areas and destinations';

  @override
  String get homeSuggestedTitle => 'Suggested apartments';

  @override
  String get homeNewestTitle => 'Newest apartments';

  @override
  String get homeUpcomingTitle => 'Your next booking';

  @override
  String get homeUpcomingConfirmed => 'Confirmed';

  @override
  String get homeEmpty => 'No apartments are available right now.';

  @override
  String get homeEmptyAction => 'Search for an apartment';

  @override
  String areaListingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apartments',
      one: '1 apartment',
      zero: 'No apartments',
    );
    return '$_temp0';
  }

  @override
  String get searchTitle => 'Search';

  @override
  String get searchLocationLabel => 'Location';

  @override
  String get searchLocationHint => 'Governorate, city, or area';

  @override
  String get searchAnyLocation => 'All locations';

  @override
  String get searchNoLocationMatches => 'No places match that name.';

  @override
  String get searchDatesLabel => 'Dates';

  @override
  String get searchDatesHint => 'Arrival and departure';

  @override
  String get searchGuestsLabel => 'Guests';

  @override
  String get searchGuestsAny => 'Any';

  @override
  String get searchAction => 'Search';

  @override
  String get searchFilters => 'Filters';

  @override
  String get searchClearAll => 'Clear all';

  @override
  String searchShowResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count results',
      one: 'Show 1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String get searchShowResultsUnknown => 'Show results';

  @override
  String get searchPriceRange => 'Nightly price';

  @override
  String get searchMinBedrooms => 'Minimum bedrooms';

  @override
  String get searchMinBathrooms => 'Minimum bathrooms';

  @override
  String get searchAnyCount => 'Any';

  @override
  String get searchAmenities => 'Amenities';

  @override
  String get searchPropertyType => 'Property type';

  @override
  String get searchSort => 'Sort';

  @override
  String get sortPriceAsc => 'Price: low to high';

  @override
  String get sortPriceDesc => 'Price: high to low';

  @override
  String get sortNewest => 'Newest';

  @override
  String get searchNoResults =>
      'No apartments are available for these criteria.';

  @override
  String get searchNoResultsHint => 'Try changing the dates or filters.';

  @override
  String get searchDatesNeededHint => 'Choose dates to be able to book.';

  @override
  String get searchDatesDropped =>
      'The dates in the link have passed. Choose new dates.';

  @override
  String get searchChooseDates => 'Choose dates';

  @override
  String get searchShare => 'Share search';

  @override
  String get shareSearchText => 'Search on OnAir';

  @override
  String nightlyPrice(String price) {
    return '$price / night';
  }

  @override
  String stayTotal(int nights, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: 'Total for $nights nights: $total',
      one: 'Total for 1 night: $total',
    );
    return '$_temp0';
  }

  @override
  String filterChipRemove(String label) {
    return 'Remove filter $label';
  }

  @override
  String bedroomsAtLeast(int count) {
    return '$count+ bedrooms';
  }

  @override
  String bathroomsAtLeast(int count) {
    return '$count+ bathrooms';
  }

  @override
  String priceRangeChip(String min, String max) {
    return '$min – $max';
  }

  @override
  String get guestsDecrease => 'Fewer guests';

  @override
  String get guestsIncrease => 'More guests';

  @override
  String get countDecrease => 'Decrease';

  @override
  String get countIncrease => 'Increase';

  @override
  String get calendarConfirm => 'Done';

  @override
  String get calendarClear => 'Clear';

  @override
  String get calendarPrevMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String get calendarRangeInvalid => 'This range includes unavailable nights.';

  @override
  String get calendarRangeNotLoaded =>
      'Availability for a month in this range is still loading. Try again in a moment.';

  @override
  String get calendarRangeLoadFailed =>
      'Availability for a month in this range failed to load. Open that month and tap retry.';

  @override
  String calendarNightsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nights',
      one: '1 night',
    );
    return '$_temp0';
  }

  @override
  String calendarUnavailableDay(String date) {
    return '$date, unavailable';
  }

  @override
  String propertyBedrooms(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bedrooms',
      one: '1 bedroom',
    );
    return '$_temp0';
  }

  @override
  String propertyBathrooms(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bathrooms',
      one: '1 bathroom',
    );
    return '$_temp0';
  }

  @override
  String propertyMaxGuests(int count) {
    return 'Up to $count guests';
  }

  @override
  String propertyArea(int sqm) {
    return '$sqm m²';
  }

  @override
  String get propertyDescription => 'Description';

  @override
  String get showMore => 'Show more';

  @override
  String get showLess => 'Show less';

  @override
  String get propertyAmenities => 'Amenities';

  @override
  String get propertySeeAllAmenities => 'See all amenities';

  @override
  String get propertyLocation => 'Location';

  @override
  String get propertyRules => 'Stay rules';

  @override
  String rulesCheckIn(String time) {
    return 'Check-in from $time';
  }

  @override
  String rulesCheckOut(String time) {
    return 'Check-out by $time';
  }

  @override
  String rulesVisitorsAllowed(int count) {
    return 'Visitors allowed (up to $count)';
  }

  @override
  String get rulesVisitorsAllowedNoLimit => 'Visitors allowed';

  @override
  String get rulesVisitorsNotAllowed => 'Visitors not allowed';

  @override
  String get propertyPolicy => 'Deposit and cancellation';

  @override
  String policyDepositPercent(String percent) {
    return 'The deposit is $percent% of the booking total.';
  }

  @override
  String policyDepositFixed(String amount) {
    return 'The deposit is $amount.';
  }

  @override
  String get policyDepositFull => 'This booking is paid in full upfront.';

  @override
  String policyFreeCancellation(int hours) {
    return 'Free cancellation up to $hours hours before check-in, with a full refund.';
  }

  @override
  String get policyAfterDeadline =>
      'If you cancel after that and before the stay, you lose only the deposit and get the rest back.';

  @override
  String get policyFullyPaidLate =>
      'If the booking is fully paid and you cancel more than 24 hours after check-in time, it is not refundable.';

  @override
  String get propertyAvailability => 'Availability';

  @override
  String get propertyReviews => 'Reviews';

  @override
  String reviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get reviewsNone => 'No reviews yet.';

  @override
  String get reviewsSeeAll => 'See all reviews';

  @override
  String ratingSemantics(String rating, int count) {
    return 'Rated $rating out of 5, $count reviews';
  }

  @override
  String get propertyContactOnAir => 'Have a question? Contact OnAir';

  @override
  String get bookNow => 'Book now';

  @override
  String get propertyTermsUpdated =>
      'The terms were updated. Review them before booking.';

  @override
  String get propertyShare => 'Share';

  @override
  String get galleryOpen => 'Open photos';

  @override
  String get galleryClose => 'Close';

  @override
  String galleryPhotoPosition(int current, int total) {
    return 'Photo $current of $total';
  }

  @override
  String get galleryEmpty => 'This property has no photos.';

  @override
  String get bookingEntryTitle => 'Booking';

  @override
  String get bookingEntryComingSoon => 'Booking in the app opens soon.';

  @override
  String get bookingEntryTermsCarried =>
      'The terms you saw are attached to this request.';

  @override
  String get supportEntryTitle => 'Contact OnAir';

  @override
  String get supportEntryComingSoon => 'Support in the app opens soon.';
}

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
      'This person isn\'t authorized to collect payments for this apartment. Don\'t hand over cash; contact OnAir.';

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
  String get favoriteAdd => 'Add to favorites';

  @override
  String get favoriteRemove => 'Remove from favorites';

  @override
  String get favoriteSaveFailed => 'Couldn\'t update favorites. Try again.';

  @override
  String get favoritesLoadFailed => 'Couldn\'t load favorites. Try again.';

  @override
  String get accountEmpty => 'Your account details will appear here.';

  @override
  String get authLoginTitle => 'Welcome to OnAir';

  @override
  String get authRegisterTitle => 'Create your account';

  @override
  String get authPhoneInvalid =>
      'Enter a valid 11-digit Egyptian mobile number.';

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
  String get authFieldRequired => 'This field is required.';

  @override
  String get authCodeRequired => 'Enter the verification code.';

  @override
  String get authCodeIncomplete => 'Enter all 6 digits of the code.';

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
  String get homeSuggestedTitle => 'Available today';

  @override
  String get propertyViewDetails => 'View details';

  @override
  String get propertyAvailableBadge => 'Available';

  @override
  String get propertyAvailableTonight => 'Available tonight';

  @override
  String get propertyBookedTonight => 'Booked tonight';

  @override
  String get homeNewestTitle => 'Newest apartments';

  @override
  String get homeUpcomingTitle => 'Your next booking';

  @override
  String get homeUpcomingConfirmed => 'Confirmed';

  @override
  String get homeEmpty =>
      'No apartments to show right now. Try a different destination or dates.';

  @override
  String homeSectionError(String section) {
    return 'Couldn\'t load $section. Try again.';
  }

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
  String get supportEntryTitle => 'Contact OnAir';

  @override
  String get supportEntryComingSoon => 'Support in the app opens soon.';

  @override
  String get errorAccountSuspended =>
      'Your account is suspended. Please contact support.';

  @override
  String get authPhoneAlreadyUsed =>
      'This number is already used by another account.';

  @override
  String get bookingPolicyOutOfBounds =>
      'The price is not fixed for these dates. Try other dates or contact support.';

  @override
  String get errorConflict => 'The data changed. Refresh and try again.';

  @override
  String get bookingStateChanged =>
      'The booking status changed. Please refresh.';

  @override
  String get errorDuplicateOperation => 'This operation was already done.';

  @override
  String get paymentVerificationIssue =>
      'There is an issue verifying the payment. Our team will contact you.';

  @override
  String get close => 'Close';

  @override
  String get bookingDatesTitle => 'Choose dates';

  @override
  String get bookingPickCheckIn => 'Pick your check-in day';

  @override
  String get bookingPickCheckOut => 'Pick your check-out day';

  @override
  String get bookingRangeHasUnavailable =>
      'This range includes an unavailable day. Choose other dates.';

  @override
  String bookingNightsCount(String count) {
    return 'Nights: $count';
  }

  @override
  String get bookingContinue => 'Continue';

  @override
  String get bookingBackToProperty => 'Back to apartment';

  @override
  String get bookingStepCheckIn => 'Check-in';

  @override
  String get bookingStepCheckOut => 'Check-out';

  @override
  String get calendarToday => 'today';

  @override
  String get bookingDetailsTitle => 'Booking details';

  @override
  String amountWas(String amount) {
    return 'was $amount';
  }

  @override
  String get bookingStartFromProperty =>
      'Start the booking from the apartment page.';

  @override
  String get bookingSummaryTitle => 'Booking summary';

  @override
  String get bookingNights => 'Nights';

  @override
  String get bookingNightlyPrice => 'Price per night';

  @override
  String get bookingTotal => 'Total';

  @override
  String get bookingPayNow => 'Due now';

  @override
  String get bookingRemaining => 'Remaining';

  @override
  String bookingRemainingDue(String date) {
    return 'Due before $date';
  }

  @override
  String get bookingPolicyTitle => 'Terms and cancellation policy';

  @override
  String get bookingSummaryOwnerNotice =>
      'Your request goes to the owner after payment. If they decline or do not reply within 24 hours, you get a full refund.';

  @override
  String get bookingGoToPayment => 'Go to payment';

  @override
  String get paymentReturnHint =>
      'If you finished paying, tap here so we can check it.';

  @override
  String get paymentCheckStatus => 'Check payment';

  @override
  String get paymentVerifying => 'Verifying your payment…';

  @override
  String get paymentVerifyingBody =>
      'This can take a few minutes. We will notify you once it is confirmed.';

  @override
  String get paymentSuccessTitle =>
      'Payment received and your request was sent to the owner';

  @override
  String get paymentSuccessBody =>
      'The dates are held for you until the owner replies.';

  @override
  String ownerDeadlineCountdown(String time) {
    return 'The owner has $time to reply';
  }

  @override
  String get paymentViewBooking => 'View booking';

  @override
  String get paymentFailedTitle => 'The payment was not completed';

  @override
  String get paymentFailedBody => 'Nothing was charged.';

  @override
  String get paymentTryAgain => 'Try again';

  @override
  String get paymentConflictTitle =>
      'These dates were booked before your payment completed';

  @override
  String paymentConflictBody(String amount) {
    return 'You will get a full refund ($amount).';
  }

  @override
  String get paymentFindOtherDates => 'Find other dates';

  @override
  String get paymentTimeoutTitle =>
      'We have not received payment confirmation yet';

  @override
  String get paymentTimeoutBody =>
      'Don\'t worry and don\'t pay again. We will notify you once it is confirmed.';

  @override
  String get paymentResumeCheckout => 'Return to checkout';

  @override
  String get paymentGoToBookings => 'Go to My Bookings';

  @override
  String get mockPaymentTitle => 'Test payment page';

  @override
  String get mockPaySuccess => 'Succeed';

  @override
  String get mockPayFailure => 'Fail';

  @override
  String get mockPayConflict => 'Succeed with conflict';

  @override
  String get mockPaySilent => 'Server never answers';

  @override
  String get mockPayClose => 'Close the page';

  @override
  String get verifyTitle => 'Confirm your details';

  @override
  String get verifyIntro =>
      'Before your first booking we confirm your email and mobile number with a code sent to your email.';

  @override
  String get verifyEmailCodeHint => 'Enter the code sent to your email';

  @override
  String get bookingsTabCurrent => 'Current';

  @override
  String get bookingsTabPast => 'Past';

  @override
  String get bookingsTabCancelled => 'Cancelled';

  @override
  String get bookingsEmptyCurrent => 'No current bookings.';

  @override
  String get bookingsEmptyPast => 'No past stays.';

  @override
  String get bookingsEmptyCancelled => 'No cancelled bookings.';

  @override
  String get bookingsFindApartment => 'Find an apartment';

  @override
  String lastUpdated(String time) {
    return 'Last updated: $time';
  }

  @override
  String get bookingsOfflineHint => 'Check your connection and try again.';

  @override
  String get bookingsStatusUpdating => 'Updating status…';

  @override
  String get bookingNeedsActionLead => 'Needs your action:';

  @override
  String ownerDeadlineDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get bookingStatusPaymentPending => 'Payment not completed';

  @override
  String get bookingStatusPaymentVerifying => 'Verifying payment';

  @override
  String get bookingStatusAwaitingOwner => 'Awaiting owner';

  @override
  String get bookingStatusPaymentConflict => 'Dates taken first';

  @override
  String get bookingStatusConfirmed => 'Confirmed';

  @override
  String get bookingStatusCheckedIn => 'Stay in progress';

  @override
  String get bookingStatusCompleted => 'Stay completed';

  @override
  String get bookingStatusRejected => 'Declined by owner';

  @override
  String get bookingStatusExpired => 'Owner did not reply';

  @override
  String get bookingStatusCancelled => 'Cancelled';

  @override
  String get bookingStatusNoShow => 'No-show';

  @override
  String get bookingStatusAbandoned => 'Not completed';

  @override
  String get bookingStatusUnknown => 'Booking update';

  @override
  String get bookingMsgPaymentPending =>
      'Payment is not completed yet. Complete it to send your request to the owner.';

  @override
  String get bookingMsgPaymentVerifying =>
      'We are verifying your payment. This can take minutes; we will notify you once confirmed.';

  @override
  String bookingMsgAwaitingOwner(String deadline) {
    return 'Paid and sent to the owner. The owner has until $deadline to reply. The dates are held for you until then.';
  }

  @override
  String get bookingMsgAwaitingOwnerNoDeadline =>
      'Paid and sent to the owner. The dates are held for you until they reply.';

  @override
  String get bookingMsgConfirmed => 'Your booking is confirmed!';

  @override
  String bookingMsgConfirmedWithRemaining(String amount) {
    return 'Your booking is confirmed! $amount must be paid before check-in.';
  }

  @override
  String get bookingMsgCheckedIn => 'Enjoy your stay.';

  @override
  String get bookingMsgCompleted =>
      'Your stay is complete. Tell us how it went!';

  @override
  String bookingMsgRejected(String amount) {
    return 'The owner declined. You will get a full refund ($amount). The OnAir team may contact you with an alternative.';
  }

  @override
  String bookingMsgExpired(String amount) {
    return 'The owner did not reply within 24 hours. You will get a full refund ($amount).';
  }

  @override
  String get bookingMsgCancelled => 'The booking was cancelled.';

  @override
  String get bookingMsgNoShow =>
      'A no-show was recorded. Contact support with any questions.';

  @override
  String bookingMsgConflict(String amount) {
    return 'These dates were booked before your payment completed. You will get a full refund ($amount).';
  }

  @override
  String get bookingMsgAbandoned =>
      'The payment was not completed and nothing was charged.';

  @override
  String get bookingMsgUnknown =>
      'There is an update on your booking. Contact support with any questions.';

  @override
  String get bookingCode => 'Booking number';

  @override
  String get bookingCopyCode => 'Copy booking number';

  @override
  String get bookingCodeCopied => 'Booking number copied';

  @override
  String get bookingStayTitle => 'Stay';

  @override
  String get bookingArrival => 'Arrival';

  @override
  String get bookingDeparture => 'Departure';

  @override
  String get bookingCheckInTime => 'Check-in time';

  @override
  String get bookingCheckOutTime => 'Check-out time';

  @override
  String get bookingPaymentsTitle => 'Payments';

  @override
  String get bookingPaid => 'Paid';

  @override
  String get paymentMethodCard => 'Card / wallet';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentLineSucceeded => 'Done';

  @override
  String get paymentLinePending => 'In progress';

  @override
  String get paymentLineFailed => 'Not completed';

  @override
  String get bookingAddressTitle => 'Address';

  @override
  String get bookingArrivalInstructions => 'Arrival instructions';

  @override
  String get bookingSavedTermsTitle => 'Terms at booking time';

  @override
  String get bookingTimelineTitle => 'Booking history';

  @override
  String get bookingEventGeneric => 'Booking update';

  @override
  String get bookingContactSupport => 'Need help? Contact OnAir';

  @override
  String get refundChipRequested => 'Refund requested';

  @override
  String get refundChipInProgress => 'Refund in progress';

  @override
  String get refundChipDone => 'Refunded';

  @override
  String get refundChipProblem => 'Refund issue';

  @override
  String get refundTitle => 'Refund';

  @override
  String get refundAmount => 'Refund amount';

  @override
  String get refundStageRequested => 'Requested';

  @override
  String get refundStageApproved => 'Approved';

  @override
  String get refundStageExecuting => 'In progress';

  @override
  String get refundStageVerified => 'Received';

  @override
  String get refundProblemHint =>
      'There is an issue with the refund. The OnAir team is on it; you can contact support.';

  @override
  String get unfinishedPaymentBanner => 'You have an unfinished payment.';

  @override
  String get unfinishedPaymentOpen => 'View';

  @override
  String get quoteChangedNotice =>
      'The price was updated. Review the new amounts before paying.';

  @override
  String get quoteConfirmNew => 'Confirm new amounts';

  @override
  String get termsChangedNotice =>
      'The terms were updated. Review and accept them to continue.';

  @override
  String get termsAcceptNew => 'I accept the new terms';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsFilterAll => 'All';

  @override
  String get notificationsFilterBooking => 'Booking';

  @override
  String get notificationsFilterPayment => 'Payment';

  @override
  String get notificationsFilterOffers => 'Offers';

  @override
  String get notificationsFilterReplies => 'Replies';

  @override
  String get notificationsFilterHint => 'Filter notifications';

  @override
  String get notificationsFilterEmpty => 'No notifications in this category.';

  @override
  String get notificationsJustNow => 'Just now';

  @override
  String notificationsMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String notificationsHoursAgo(int count) {
    return '$count hr ago';
  }

  @override
  String notificationsDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String notificationsWeeksAgo(int count) {
    return '$count weeks ago';
  }

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String get notificationsOffNotice =>
      'Notifications are off. Turn them on to know as soon as the owner replies.';

  @override
  String get notificationsOpenSettings => 'Open settings';

  @override
  String get pushPermissionTitle => 'Turn on notifications';

  @override
  String get pushPermissionBody =>
      'So you know as soon as the owner replies to your request.';

  @override
  String get pushPermissionEnable => 'Turn on';

  @override
  String get pushPermissionLater => 'Not now';

  @override
  String unreadBadge(String count) {
    return '$count unread notifications';
  }

  @override
  String get notifBookingRequestReceivedTitle => 'Request sent';

  @override
  String get notifBookingRequestReceivedBody =>
      'The owner replies within 24 hours. Tap for details.';

  @override
  String get notifBookingConfirmedTitle => 'Booking confirmed';

  @override
  String get notifBookingConfirmedBody => 'Tap for details.';

  @override
  String get notifBookingRejectedTitle => 'Request declined';

  @override
  String get notifBookingRejectedBody =>
      'You will get a full refund. Tap for details.';

  @override
  String get notifBookingExpiredTitle => 'No reply in time';

  @override
  String get notifBookingExpiredBody =>
      'You will get a full refund. Tap for details.';

  @override
  String get notifBookingPaymentConflictTitle => 'Dates taken first';

  @override
  String get notifBookingPaymentConflictBody =>
      'You will get a full refund. Tap for details.';

  @override
  String get notifBookingCancelledByGuestTitle => 'Booking cancelled';

  @override
  String get notifBookingCancelledByGuestBody => 'Tap for details.';

  @override
  String get notifBookingCancelledByPlatformTitle =>
      'Booking cancelled by OnAir';

  @override
  String get notifBookingCancelledByPlatformBody => 'Tap for details.';

  @override
  String get notifBookingReplacementOfferedTitle => 'Alternative offer';

  @override
  String get notifBookingReplacementOfferedBody => 'Tap to review the offer.';

  @override
  String get notifBookingNoShowRecordedTitle => 'No-show recorded';

  @override
  String get notifBookingNoShowRecordedBody => 'Tap for details.';

  @override
  String get notifBookingReopenedTitle => 'Booking reopened';

  @override
  String get notifBookingReopenedBody => 'Tap for details.';

  @override
  String get notifPaymentFailedTitle => 'Payment not completed';

  @override
  String get notifPaymentFailedBody => 'Nothing was charged.';

  @override
  String get notifPaymentRemainingDueTitle => 'Remaining amount due';

  @override
  String get notifPaymentRemainingDueBody => 'Pay it before check-in.';

  @override
  String get notifPaymentRemainingPaidTitle => 'Remaining amount paid';

  @override
  String get notifPaymentRemainingPaidBody => 'Tap for details.';

  @override
  String get notifCashConfirmationRequestedTitle => 'Confirm cash payment';

  @override
  String get notifCashConfirmationRequestedBody => 'The code is in your email.';

  @override
  String get notifCashPaymentConfirmedTitle => 'Cash payment confirmed';

  @override
  String get notifCashPaymentConfirmedBody => 'Tap for the receipt.';

  @override
  String get notifStayCheckinReminderTitle => 'Check-in is soon';

  @override
  String get notifStayCheckinReminderBody => 'Tap for details.';

  @override
  String get notifStayCheckoutReminderTitle => 'Check-out is soon';

  @override
  String get notifStayCheckoutReminderBody => 'Tap for details.';

  @override
  String get notifStayHostHandoverConfirmedTitle => 'Owner confirmed handover';

  @override
  String get notifStayHostHandoverConfirmedBody =>
      'Confirm you received the apartment.';

  @override
  String get notifStayCheckedInTitle => 'Your stay started';

  @override
  String get notifStayCheckedInBody => 'Enjoy your stay.';

  @override
  String get notifStayCompletedTitle => 'Your stay is complete';

  @override
  String get notifStayCompletedBody => 'Tell us how it went!';

  @override
  String get notifDamageClaimOpenedTitle => 'A claim was opened';

  @override
  String get notifDamageClaimOpenedBody => 'Tap to review.';

  @override
  String get notifDamageResolvedTitle => 'Claim resolved';

  @override
  String get notifDamageResolvedBody => 'Tap for details.';

  @override
  String get notifRefundRequestedTitle => 'Refund requested';

  @override
  String get notifRefundRequestedBody => 'Tap for details.';

  @override
  String get notifRefundExecutedTitle => 'Refund in progress';

  @override
  String get notifRefundExecutedBody => 'Tap for details.';

  @override
  String get notifRefundVerifiedTitle => 'Refund received';

  @override
  String get notifRefundVerifiedBody => 'Tap for details.';

  @override
  String get notifSupportStaffRepliedTitle => 'New reply from support';

  @override
  String get notifSupportStaffRepliedBody => 'Tap to read.';

  @override
  String get notifSupportCaseResolvedTitle => 'Your case is resolved';

  @override
  String get notifSupportCaseResolvedBody => 'Tap for details.';

  @override
  String get notifReviewApprovedTitle => 'Your review is published';

  @override
  String get notifReviewApprovedBody => 'Thanks for sharing.';

  @override
  String get notifReviewRejectedTitle => 'Your review was not published';

  @override
  String get notifReviewRejectedBody => 'Tap for details.';

  @override
  String get notifAccountPhoneChangedTitle => 'Mobile number changed';

  @override
  String get notifAccountPhoneChangedBody =>
      'If this wasn\'t you, contact support.';

  @override
  String get notifAccountPasswordChangedTitle => 'Password changed';

  @override
  String get notifAccountPasswordChangedBody =>
      'If this wasn\'t you, contact support.';

  @override
  String get notifGenericTitle => 'You have a new update';

  @override
  String get notifGenericBody => 'Tap for details.';

  @override
  String get stayCashNotAllowed =>
      'Cash payment isn\'t available for this apartment.';

  @override
  String get stayCashAmountChanged =>
      'The remaining amount changed. Check the new amount.';

  @override
  String get stayRemainingNotPaid =>
      'Pay the remaining amount before receiving the apartment.';

  @override
  String get cancellationTermsChanged =>
      'The refund amount changed. Review the new details.';

  @override
  String get claimAlreadyAnswered => 'This claim was already answered.';

  @override
  String get offerNotAvailable => 'This offer is no longer available.';

  @override
  String get stayNeedsConnection => 'This step needs an internet connection.';

  @override
  String get stayStepNotAvailable => 'This step isn\'t available right now.';

  @override
  String get stayActionDone => 'Done, it\'s saved.';

  @override
  String get dialogConfirm => 'Confirm';

  @override
  String get dialogBack => 'Back';

  @override
  String get actionPayRemaining => 'Pay the remaining amount';

  @override
  String get actionConfirmCash => 'Confirm a cash payment';

  @override
  String get actionCancelBooking => 'Cancel booking';

  @override
  String get actionConfirmCheckin => 'I received the apartment';

  @override
  String get actionConfirmCheckout => 'I left the apartment';

  @override
  String get actionRespondClaim => 'Respond to the claim';

  @override
  String bookingNeedsAction(String action) {
    return 'Needs your action: $action';
  }

  @override
  String get bookingMsgWaitingHandover =>
      'You confirmed. Waiting for the owner to confirm the handover.';

  @override
  String get bookingMsgHostHandedOver =>
      'The owner confirmed the handover. Confirm you received the apartment.';

  @override
  String get bookingMsgWaitingCheckout =>
      'You confirmed leaving. Waiting for the owner to confirm receiving the apartment.';

  @override
  String get bookingMsgCancelledByGuest =>
      'You cancelled this booking. Refund details are below.';

  @override
  String get bookingMsgCancelledByPlatform =>
      'OnAir cancelled this booking. Refund details are below.';

  @override
  String get bookingMsgReopened =>
      'Your booking was reopened. Pay the remaining amount before check-in.';

  @override
  String get ackTitleCheckin => 'Apartment handover';

  @override
  String get ackTitleCheckout => 'Leaving the apartment';

  @override
  String get ackYou => 'You';

  @override
  String get ackOwner => 'Owner';

  @override
  String ackConfirmedAt(String time) {
    return 'Confirmed $time';
  }

  @override
  String get ackWaiting => 'Waiting';

  @override
  String get ackKeyLeftSafe => 'Key left in the agreed place';

  @override
  String get checkinSheetTitle => 'Did you actually receive the apartment?';

  @override
  String get checkinSheetBody =>
      'Confirm only if you received the apartment and the keys.';

  @override
  String get checkinSheetConfirm => 'Yes, I received it';

  @override
  String get checkoutSheetTitle => 'Did you leave the apartment?';

  @override
  String get checkoutSheetBody =>
      'Confirm after you leave the apartment and hand over the keys.';

  @override
  String get checkoutSheetConfirm => 'Yes, I left';

  @override
  String get sheetNotYet => 'Not yet';

  @override
  String get checkinProblem => 'I have a problem with the handover';

  @override
  String get remainingTitle => 'Pay the remaining amount';

  @override
  String get remainingNote =>
      'The remaining amount must be paid before you receive the apartment.';

  @override
  String get remainingDueLabel => 'Due by';

  @override
  String get remainingChooseMethod => 'How will you pay?';

  @override
  String get remainingOptionOnline => 'Pay online';

  @override
  String get remainingOptionCash => 'I paid / will pay in cash';

  @override
  String remainingPayButton(String amount) {
    return 'Pay $amount';
  }

  @override
  String get remainingCashButton => 'Continue to cash confirmation';

  @override
  String get remainingPaidTitle => 'Remaining amount paid';

  @override
  String get remainingPaidBody => 'Your booking is now fully paid.';

  @override
  String get remainingFailedBody =>
      'The payment wasn\'t completed and nothing was charged. You can try again.';

  @override
  String get cashTitle => 'Confirm a cash payment';

  @override
  String get cashAmountLabel => 'Amount';

  @override
  String get cashAmountLocked => 'Amount, not editable';

  @override
  String get cashPhoneLabel =>
      'Mobile number of the person who received the cash';

  @override
  String get cashPhoneHint => '01xxxxxxxxx';

  @override
  String get cashPhoneInvalid => 'Enter a valid Egyptian mobile number.';

  @override
  String get cashWarning => 'Only hand cash to a person authorized by OnAir.';

  @override
  String get cashSendCode => 'Send the code to my email';

  @override
  String cashCodeSent(String email) {
    return 'We sent a code to $email';
  }

  @override
  String get cashCollectorLabel => 'Received by';

  @override
  String cashStatement(String amount, String name) {
    return 'I confirm I handed $amount in cash to $name';
  }

  @override
  String get cashResend => 'Resend code';

  @override
  String cashResendIn(String time) {
    return 'Resend in $time';
  }

  @override
  String get cashConfirmButton => 'Confirm payment';

  @override
  String get cashContactSupport => 'Contact support';

  @override
  String get receiptTitle => 'Cash payment confirmed';

  @override
  String get receiptNumber => 'Receipt number';

  @override
  String get receiptDate => 'Date';

  @override
  String get receiptBack => 'Back to booking';

  @override
  String get receiptShow => 'Show receipt';

  @override
  String get receiptCopied => 'Receipt number copied';

  @override
  String get cancelTitle => 'Cancel booking';

  @override
  String get cancelRefund => 'Refunded to you';

  @override
  String get cancelNonRefundable => 'Not refundable';

  @override
  String cancelReasonFree(String amount) {
    return 'Free cancellation. You\'ll get the full amount back ($amount).';
  }

  @override
  String cancelReasonDepositLost(String refund, String deposit, String date) {
    return '$refund will be refunded. The $deposit deposit isn\'t refundable because free cancellation ended on $date.';
  }

  @override
  String cancelReasonDepositLostNoDate(String refund, String deposit) {
    return '$refund will be refunded. The $deposit deposit isn\'t refundable because free cancellation has ended.';
  }

  @override
  String get cancelReasonNoRefund =>
      'No refund, because the booking is fully paid and more than 24 hours have passed since the scheduled check-in.';

  @override
  String get cancelReasonTitle => 'Reason (optional)';

  @override
  String get cancelReasonChangeOfPlans => 'My plans changed';

  @override
  String get cancelReasonFoundOther => 'I found another place';

  @override
  String get cancelReasonTravelProblem => 'Travel problem';

  @override
  String get cancelReasonOther => 'Other';

  @override
  String get cancelReasonOtherHint => 'Write the reason';

  @override
  String get cancelKeep => 'Keep my booking';

  @override
  String get cancelDialogTitle => 'Are you sure you want to cancel?';

  @override
  String cancelDialogBody(String amount) {
    return '$amount will be refunded.';
  }

  @override
  String get cancelDialogConfirm => 'Yes, cancel';

  @override
  String get claimTitle => 'Damage claim';

  @override
  String get claimsSectionTitle => 'Damage claims';

  @override
  String get claimProtection =>
      'No amount will be deducted without your agreement or a decision from OnAir.';

  @override
  String get claimAmount => 'Amount claimed';

  @override
  String get claimEvidence => 'Photos';

  @override
  String claimEvidencePhoto(String index, String count) {
    return 'Photo $index of $count';
  }

  @override
  String get claimPhotoFailed => 'The photo didn\'t load. Tap to retry.';

  @override
  String get claimAgree => 'I agree';

  @override
  String get claimDispute => 'I dispute';

  @override
  String get claimAgreeDialogTitle => 'Agree to the claim?';

  @override
  String claimAgreeDialogBody(String amount) {
    return 'You agree to $amount.';
  }

  @override
  String get claimDisputeReason => 'Reason for the dispute';

  @override
  String get claimDisputeReasonHint => 'Describe what happened';

  @override
  String get claimDisputeTooShort => 'Write at least 10 characters.';

  @override
  String get claimDisputeSend => 'Send dispute';

  @override
  String claimCaseNumber(String number) {
    return 'Case number: $number';
  }

  @override
  String get claimYourAnswer => 'Your answer';

  @override
  String get claimStatusOpen => 'Waiting for you';

  @override
  String get claimStatusAccepted => 'You agreed';

  @override
  String get claimStatusDisputed => 'You disputed';

  @override
  String get claimStatusMediation => 'Under review by OnAir';

  @override
  String get claimStatusResolved => 'Resolved';

  @override
  String get claimStatusWithdrawn => 'Withdrawn';

  @override
  String get claimStatusUnknown => 'Updated';

  @override
  String claimOutcomeGuestPays(String amount) {
    return 'Decision: you pay $amount.';
  }

  @override
  String claimOutcomePartial(String amount) {
    return 'Decision: you pay part of the amount ($amount).';
  }

  @override
  String get claimOutcomeNoCharge => 'Decision: you don\'t pay anything.';

  @override
  String get claimOutcomeWithdrawn => 'The owner withdrew the claim.';

  @override
  String get offerTitle => 'Alternative offer from OnAir';

  @override
  String offerPayMore(String amount) {
    return 'You will pay $amount more.';
  }

  @override
  String offerRefundDiff(String amount) {
    return '$amount will be refunded to you.';
  }

  @override
  String get offerNoDiff => 'No price difference.';

  @override
  String offerExpires(String time) {
    return 'Answer before $time';
  }

  @override
  String get offerAccept => 'I accept';

  @override
  String get offerDecline => 'No, I want my refund';

  @override
  String get offerAcceptDialogTitle => 'Accept the alternative offer?';

  @override
  String get offerDeclineDialogTitle => 'Decline the alternative offer?';

  @override
  String get offerDeclineDialogBody => 'Your refund will continue as before.';

  @override
  String get offerStatusAccepted => 'You accepted the offer';

  @override
  String get offerStatusDeclined => 'You declined the offer';

  @override
  String get offerStatusExpired => 'The offer expired';

  @override
  String get mockToolsTitle => 'Mock tools';

  @override
  String get mockOwnerHandover => 'Owner confirms handover';

  @override
  String get mockOwnerCheckout => 'Owner confirms checkout';

  @override
  String get mockOwnerCheckoutKey => 'Owner confirms checkout (key left safe)';

  @override
  String get mockCollectorCash => 'Collector records cash';

  @override
  String get mockOpenClaim => 'Open a claim';

  @override
  String get mockAdvanceRefund => 'Advance the refund stage';

  @override
  String get mockChangeTerms => 'Change cancellation terms once';

  @override
  String get offerDates => 'Dates';

  @override
  String placeAreaCity(String area, String city) {
    return '$area, $city';
  }

  @override
  String get authOr => 'or';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get authSocialFailed => 'Couldn\'t sign you in. Please try again.';

  @override
  String get confirmPhoneTitle => 'Confirm your number';

  @override
  String get confirmPhoneNewTitle => 'Change phone number';

  @override
  String get confirmPhoneSubtitle =>
      'We\'ll send a code to this number on WhatsApp to make sure it\'s yours.';

  @override
  String get confirmPhoneEmailLabel => 'Your account';

  @override
  String get confirmPhoneContinue => 'Continue';

  @override
  String get confirmPhoneCancel => 'Cancel';

  @override
  String get confirmPhoneLeaveTitle => 'Leave registration?';

  @override
  String get confirmPhoneLeaveBody =>
      'If you leave, your registration won\'t be completed.';

  @override
  String get confirmPhoneLeaveConfirm => 'Leave';

  @override
  String get confirmPhoneLeaveStay => 'Stay';

  @override
  String get whatsappCodeTitle => 'Enter the code';

  @override
  String whatsappCodeSentTo(String phone) {
    return 'We sent a code to $phone on WhatsApp';
  }

  @override
  String get whatsappOpen => 'Open WhatsApp';

  @override
  String get whatsappConfirm => 'Confirm';

  @override
  String get whatsappResend => 'Send a new code';

  @override
  String whatsappResendIn(String time) {
    return 'You can request a new code in $time';
  }

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get whatsappEditNumber => 'Change number';

  @override
  String get whatsappNotOnWhatsApp =>
      'This number isn\'t on WhatsApp. Use a number that has WhatsApp.';

  @override
  String get whatsappContactSupport => 'Contact support';

  @override
  String get whatsappUseLatestCode => 'Use the latest code you received.';

  @override
  String otpBlockedUntil(String date) {
    return 'Code sending is paused until $date. Contact support if you need help.';
  }

  @override
  String get otpAttestationFailed =>
      'We couldn\'t verify this app. Update it from the store and try again.';

  @override
  String get otpTemporarilyUnavailable =>
      'The service is busy right now. Try again shortly.';

  @override
  String get otpAttemptsExceeded => 'Too many attempts. Request a new code.';

  @override
  String get confirmPhoneWelcome => 'Welcome to OnAir';

  @override
  String get phoneChanged => 'Your number was changed';

  @override
  String get accountSignInMethod => 'Sign-in method';

  @override
  String get accountMethodGoogle => 'Google';

  @override
  String get accountMethodApple => 'Apple';

  @override
  String get accountMethodEmail => 'Email';

  @override
  String get accountPhone => 'Phone number';

  @override
  String get accountPhoneConfirmed => 'Confirmed';

  @override
  String get accountChangePhone => 'Change';

  @override
  String get verifyPhoneOnWhatsApp => 'Confirm your number on WhatsApp';
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/presentation/booking_action_ui.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('ar'));

  test('maps every booking action label', () {
    expect(
      bookingActionLabel(BookingActionCode.payRemaining, l10n),
      l10n.actionPayRemaining,
    );
    expect(
      bookingActionLabel(BookingActionCode.confirmCashPayment, l10n),
      l10n.actionConfirmCash,
    );
    expect(
      bookingActionLabel(BookingActionCode.requestCancellation, l10n),
      l10n.actionCancelBooking,
    );
    expect(
      bookingActionLabel(BookingActionCode.confirmCheckin, l10n),
      l10n.actionConfirmCheckin,
    );
    expect(
      bookingActionLabel(BookingActionCode.confirmCheckout, l10n),
      l10n.actionConfirmCheckout,
    );
    expect(
      bookingActionLabel(BookingActionCode.respondDamageClaim, l10n),
      l10n.actionRespondClaim,
    );
    expect(
      bookingActionLabel(BookingActionCode.contactSupport, l10n),
      l10n.bookingContactSupport,
    );
    expect(
      bookingActionLabel(const BookingActionCode('unknown'), l10n),
      l10n.bookingContactSupport,
    );
  });
}

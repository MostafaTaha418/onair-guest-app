import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_stay_parts.dart';
import 'package:on_air/features/stay/presentation/stay_ack/stay_ack_sheets.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

String bookingActionLabel(
  BookingActionCode code,
  AppLocalizations l10n,
) => switch (code.value) {
  'pay_remaining' => l10n.actionPayRemaining,
  'confirm_cash_payment' => l10n.actionConfirmCash,
  'request_cancellation' => l10n.actionCancelBooking,
  'confirm_checkin' => l10n.actionConfirmCheckin,
  'confirm_checkout' => l10n.actionConfirmCheckout,
  'respond_damage_claim' => l10n.actionRespondClaim,
  'contact_support' => l10n.bookingContactSupport,
  _ => l10n.bookingContactSupport,
};

Future<bool> launchBookingAction(
  BuildContext context,
  BookingDetails details,
  BookingActionCode code,
) async {
  switch (code.value) {
    case 'pay_remaining':
      return await context.push<bool>(AppRoutes.remainingPayment(details.id)) ??
          false;
    case 'confirm_cash_payment':
      return await context.push<bool>(AppRoutes.cashConfirm(details.id)) ??
          false;
    case 'request_cancellation':
      return await context.push<bool>(AppRoutes.cancelBooking(details.id)) ??
          false;
    case 'confirm_checkin':
      return showCheckInSheet(context, details);
    case 'confirm_checkout':
      return showCheckOutSheet(context, details);
    case 'respond_damage_claim':
      for (final claim in details.damageClaims) {
        if (claim.status == DamageClaimStatus.open) {
          return await context.push<bool>(
                AppRoutes.damageClaim(details.id, claim.id),
              ) ??
              false;
        }
      }
      return false;
    case 'contact_support':
      await context.push<void>(
        '${AppRoutes.supportNew}?booking=${details.id}',
      );
      return false;
    default:
      return false;
  }
}

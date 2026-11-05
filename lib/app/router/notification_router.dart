import 'package:on_air/app/router/routes.dart';

/// Push and notification-center tap routing (contracts/app-routes-g2.md §4).
abstract final class NotificationRouter {
  /// The location a notification with [typeKey] opens.
  ///
  /// [entityType] is accepted for later phases: in G2 it is not used for
  /// routing (G2 notifications are all booking-scoped), so only the type
  /// prefix and the ID's validity decide the destination.
  static String locationFor(
    String typeKey,
    String entityType,
    String entityId, {
    Map<String, dynamic> params = const {},
  }) {
    if (typeKey.startsWith('damage.')) {
      return AppRoutes.isUuidV4(entityId)
          ? AppRoutes.damageClaimResolver(entityId)
          : AppRoutes.bookings;
    }
    if (typeKey == 'cash.payment_confirmed') {
      final bookingId = params['booking_id'];
      return bookingId is String &&
              AppRoutes.isUuidV4(bookingId) &&
              AppRoutes.isUuidV4(entityId)
          ? AppRoutes.receipt(bookingId, entityId)
          : AppRoutes.bookings;
    }
    if (typeKey == 'payment.remaining_due') {
      return AppRoutes.isUuidV4(entityId)
          ? AppRoutes.remainingPayment(entityId)
          : AppRoutes.bookings;
    }
    if (typeKey == 'cash.confirmation_requested') {
      return AppRoutes.isUuidV4(entityId)
          ? AppRoutes.cashConfirm(entityId)
          : AppRoutes.bookings;
    }
    if (typeKey == 'booking.replacement_offered') {
      return AppRoutes.isUuidV4(entityId)
          ? AppRoutes.bookingDetailsFocus(entityId, 'offer')
          : AppRoutes.bookings;
    }
    if (typeKey.startsWith('refund.')) {
      return AppRoutes.isUuidV4(entityId)
          ? AppRoutes.bookingDetailsFocus(entityId, 'payments')
          : AppRoutes.bookings;
    }
    const bookingPrefixes = [
      'booking.',
      'payment.',
      'cash.',
      'stay.',
      'refund.',
      'review.',
    ];
    final isBookingScoped = bookingPrefixes.any(typeKey.startsWith);
    if (isBookingScoped) {
      return AppRoutes.isUuidV4(entityId)
          ? AppRoutes.bookingDetails(entityId)
          : AppRoutes.bookings;
    }
    if (typeKey.startsWith('support.')) return AppRoutes.supportNew;
    if (typeKey.startsWith('account.')) return AppRoutes.account;
    return AppRoutes.bookings;
  }
}

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
    String entityId,
  ) {
    const bookingPrefixes = [
      'booking.',
      'payment.',
      'cash.',
      'stay.',
      'refund.',
      'damage.',
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

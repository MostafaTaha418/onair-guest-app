import 'package:flutter/foundation.dart';

/// A booking action code the server returned (data-model §9).
@immutable
final class BookingActionCode {
  const BookingActionCode(this.value);

  final String value;

  static const contactSupport = BookingActionCode('contact_support');
  static const payRemaining = BookingActionCode('pay_remaining');
  static const confirmCashPayment = BookingActionCode(
    'confirm_cash_payment',
  );
  static const requestCancellation = BookingActionCode(
    'request_cancellation',
  );
  static const confirmCheckin = BookingActionCode('confirm_checkin');
  static const confirmCheckout = BookingActionCode('confirm_checkout');
  static const respondDamageClaim = BookingActionCode(
    'respond_damage_claim',
  );

  @override
  bool operator ==(Object other) =>
      other is BookingActionCode && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Which action codes this phase can act on. G3/G5 add their codes to
/// `supported`; nothing else changes (FR-023). Codes outside `supported` are
/// dropped silently — no disabled button, no "coming soon".
final class BookingActionRegistry {
  const BookingActionRegistry(this.supported);

  factory BookingActionRegistry.g2() =>
      const BookingActionRegistry({'contact_support'});

  factory BookingActionRegistry.g3() => const BookingActionRegistry({
    'contact_support',
    'pay_remaining',
    'confirm_cash_payment',
    'request_cancellation',
    'confirm_checkin',
    'confirm_checkout',
    'respond_damage_claim',
  });

  final Set<String> supported;

  /// Keeps the server order, removes unsupported codes and duplicates.
  List<BookingActionCode> visible(List<String> codes) {
    final seen = <String>{};
    final result = <BookingActionCode>[];
    for (final code in codes) {
      if (!supported.contains(code) || !seen.add(code)) continue;
      result.add(BookingActionCode(code));
    }
    return result;
  }
}

BookingActionCode? firstGuestAction(List<BookingActionCode> visible) {
  for (final code in visible) {
    if (code != BookingActionCode.contactSupport &&
        code != BookingActionCode.requestCancellation &&
        code != BookingActionCode.respondDamageClaim) {
      return code;
    }
  }
  return null;
}

BookingActionCode? needsActionCode(List<BookingActionCode> visible) {
  for (final code in visible) {
    if (code != BookingActionCode.contactSupport) return code;
  }
  return null;
}

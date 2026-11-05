import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';

void main() {
  const input = [
    'write_review',
    'request_cancellation',
    'pay_remaining',
    'x_unknown',
    'contact_support',
    'pay_remaining',
  ];

  test('G3 keeps supported actions in server order without duplicates', () {
    expect(
      BookingActionRegistry.g3().visible(input).map((code) => code.value),
      ['request_cancellation', 'pay_remaining', 'contact_support'],
    );
  });

  test('G2 remains limited to contact support', () {
    expect(
      BookingActionRegistry.g2().visible(input),
      [BookingActionCode.contactSupport],
    );
  });

  test('firstGuestAction excludes destructive and support actions', () {
    final registry = BookingActionRegistry.g3();
    expect(
      firstGuestAction(
        registry.visible([
          'request_cancellation',
          'confirm_checkin',
          'pay_remaining',
        ]),
      ),
      BookingActionCode.confirmCheckin,
    );
    expect(
      firstGuestAction(
        registry.visible(['request_cancellation', 'contact_support']),
      ),
      isNull,
    );
    expect(
      firstGuestAction(registry.visible(['respond_damage_claim'])),
      isNull,
    );
  });

  test('needsActionCode excludes only contact support', () {
    final registry = BookingActionRegistry.g3();
    expect(
      needsActionCode(
        registry.visible(['contact_support', 'request_cancellation']),
      ),
      BookingActionCode.requestCancellation,
    );
    expect(
      needsActionCode(
        registry.visible(['respond_damage_claim', 'contact_support']),
      ),
      BookingActionCode.respondDamageClaim,
    );
    expect(
      needsActionCode(registry.visible(['contact_support'])),
      isNull,
    );
  });
}

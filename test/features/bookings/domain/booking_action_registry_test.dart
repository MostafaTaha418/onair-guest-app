import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';

void main() {
  test('G2 registry keeps only contact_support in server order', () {
    final registry = BookingActionRegistry.g2();
    expect(
      registry.visible([
        'pay_remaining',
        'contact_support',
        'request_cancellation',
        'totally_new',
      ]),
      [BookingActionCode.contactSupport],
    );
  });

  test('an empty list stays empty', () {
    expect(BookingActionRegistry.g2().visible([]), isEmpty);
  });

  test('duplicates collapse to one entry', () {
    expect(
      BookingActionRegistry.g2().visible([
        'contact_support',
        'contact_support',
      ]),
      [BookingActionCode.contactSupport],
    );
  });
}

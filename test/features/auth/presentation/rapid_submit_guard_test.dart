import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/auth/presentation/widgets/rapid_submit_guard.dart';

void main() {
  test('blocks rapid repeat and allows a later intentional retry', () {
    var now = DateTime.utc(2026, 11, 3);
    final guard = RapidSubmitGuard(clock: () => now);

    expect(guard.tryEnter(), isTrue);
    now = now.add(const Duration(milliseconds: 699));
    expect(guard.tryEnter(), isFalse);
    now = now.add(const Duration(milliseconds: 1));
    expect(guard.tryEnter(), isTrue);
    guard.reset();
    expect(guard.tryEnter(), isTrue);
  });
}

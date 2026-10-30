import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/time/countdown.dart';

void main() {
  test('two hours ahead: first value at once, next tick after 60 s', () {
    fakeAsync((async) {
      final start = DateTime.utc(2026, 11, 1, 10);
      var now = start;
      final countdown = Countdown(
        deadlineUtc: start.add(const Duration(hours: 2)),
        now: () => now,
      );
      final values = <Duration>[];
      final subscription = countdown.remaining.listen(values.add);
      expect(values.single, const Duration(hours: 2));

      now = start.add(const Duration(seconds: 60));
      async.elapse(const Duration(seconds: 60));
      expect(values, hasLength(2));
      expect(values.last, const Duration(hours: 1, minutes: 59));
      unawaited(subscription.cancel());
      countdown.cancel();
    });
  });

  test('under one hour: ticks every second', () {
    fakeAsync((async) {
      final start = DateTime.utc(2026, 11, 1, 10);
      var now = start;
      final countdown = Countdown(
        deadlineUtc: start.add(const Duration(minutes: 30)),
        now: () => now,
      );
      final values = <Duration>[];
      final subscription = countdown.remaining.listen(values.add);
      expect(values.single, const Duration(minutes: 30));

      now = start.add(const Duration(seconds: 1));
      async.elapse(const Duration(seconds: 1));
      now = start.add(const Duration(seconds: 2));
      async.elapse(const Duration(seconds: 1));
      expect(values, hasLength(3));
      expect(values[1], const Duration(minutes: 29, seconds: 59));
      expect(values[2], const Duration(minutes: 29, seconds: 58));
      unawaited(subscription.cancel());
      countdown.cancel();
    });
  });

  test('a past deadline emits zero once and closes', () async {
    final start = DateTime.utc(2026, 11, 1, 10);
    final countdown = Countdown(
      deadlineUtc: start.subtract(const Duration(minutes: 1)),
      now: () => start,
    );
    final values = <Duration>[];
    final done = Completer<void>();
    final subscription = countdown.remaining.listen(
      values.add,
      onDone: done.complete,
    );
    await done.future;
    await subscription.cancel();
    expect(values, [Duration.zero]);
  });

  test('nothing is emitted after cancel()', () {
    fakeAsync((async) {
      final start = DateTime.utc(2026, 11, 1, 10);
      var now = start;
      final countdown = Countdown(
        deadlineUtc: start.add(const Duration(minutes: 30)),
        now: () => now,
      );
      final values = <Duration>[];
      final subscription = countdown.remaining.listen(values.add);
      expect(values, hasLength(1));

      countdown.cancel();
      now = start.add(const Duration(seconds: 5));
      async.elapse(const Duration(seconds: 5));
      expect(values, hasLength(1));
      unawaited(subscription.cancel());
    });
  });

  test('format renders H:MM above one hour and M:SS below', () {
    expect(Countdown.format(const Duration(hours: 23, minutes: 5)), '23:05');
    expect(Countdown.format(const Duration(hours: 1)), '1:00');
    expect(
      Countdown.format(const Duration(minutes: 59, seconds: 9)),
      '59:09',
    );
    expect(Countdown.format(const Duration(seconds: 7)), '0:07');
  });
}

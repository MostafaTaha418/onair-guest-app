import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/realtime/notification_signal.dart';

void main() {
  test('fromRecord reads the four fields', () {
    final signal = NotificationSignal.fromRecord({
      'id': 'n1',
      'type_key': 'booking.confirmed',
      'entity_type': 'booking',
      'entity_id': 'b0000000-0000-4000-8000-000000000001',
    });
    expect(signal, isNotNull);
    expect(signal!.id, 'n1');
    expect(signal.typeKey, 'booking.confirmed');
    expect(signal.entityType, 'booking');
    expect(signal.entityId, 'b0000000-0000-4000-8000-000000000001');
  });

  test('fromRecord returns null without type_key or entity_id', () {
    expect(
      NotificationSignal.fromRecord({
        'id': 'n1',
        'entity_type': 'booking',
        'entity_id': 'b0000000-0000-4000-8000-000000000001',
      }),
      isNull,
    );
    expect(
      NotificationSignal.fromRecord({
        'id': 'n1',
        'type_key': 'booking.confirmed',
        'entity_type': 'booking',
      }),
      isNull,
    );
    expect(
      NotificationSignal.fromRecord({
        'type_key': 42,
        'entity_id': 'b0000000-0000-4000-8000-000000000001',
      }),
      isNull,
    );
    expect(
      NotificationSignal.fromRecord({
        'type_key': 'booking.confirmed',
        'entity_id': 42,
      }),
      isNull,
    );
  });

  test('the controllable source delivers only while started', () async {
    final source = ControllableNotificationSignalSource();
    const signal = NotificationSignal(
      id: 'n1',
      typeKey: 'booking.confirmed',
      entityType: 'booking',
      entityId: 'b0000000-0000-4000-8000-000000000001',
    );

    // Ignored before start.
    var received = <NotificationSignal>[];
    final early = source.signals.listen(received.add);
    source.emit(signal);
    await Future<void>.delayed(Duration.zero);
    expect(received, isEmpty);
    await early.cancel();

    await source.start('u1');
    received = <NotificationSignal>[];
    final first = source.signals.listen(received.add);
    source.emit(signal);
    await Future<void>.delayed(Duration.zero);
    expect(received, [signal]);

    // A second listener receives it too: the stream is broadcast.
    final mirror = <NotificationSignal>[];
    final second = source.signals.listen(mirror.add);
    source.emit(signal);
    await Future<void>.delayed(Duration.zero);
    expect(received, hasLength(2));
    expect(mirror, hasLength(1));
    await second.cancel();
    await first.cancel();

    await source.stop();
    final afterStop = <NotificationSignal>[];
    final lateListener = source.signals.listen(afterStop.add);
    source.emit(signal);
    await Future<void>.delayed(Duration.zero);
    expect(afterStop, isEmpty);
    await lateListener.cancel();
  });
}

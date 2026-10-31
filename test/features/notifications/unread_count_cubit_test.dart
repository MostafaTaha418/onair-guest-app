import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/features/notifications/domain/app_notification.dart';
import 'package:on_air/features/notifications/domain/notifications_repository.dart';
import 'package:on_air/features/notifications/presentation/unread_count_cubit.dart';

/// Serves the count and records nothing else.
final class StubNotifications implements NotificationsRepository {
  int count = 0;
  AppFailure? nextCountError;

  @override
  Future<List<AppNotification>> list({DateTime? before, int limit = 30}) =>
      throw UnimplementedError();

  @override
  Future<int> unreadCount() async {
    final error = nextCountError;
    if (error != null) {
      nextCountError = null;
      throw error;
    }
    return count;
  }

  @override
  Future<void> markRead(List<String>? ids) async {}
}

const _uuid = 'b0000000-0000-4000-8000-000000000001';

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  late StubNotifications repo;
  late ControllableNotificationSignalSource signals;
  late UnreadCountCubit cubit;

  setUp(() {
    repo = StubNotifications();
    signals = ControllableNotificationSignalSource();
    cubit = UnreadCountCubit(notifications: repo, signals: signals);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('starts at zero and refreshes from the server', () async {
    expect(cubit.state, 0);
    repo.count = 3;
    await cubit.refresh();
    expect(cubit.state, 3);
  });

  test('a signal bumps by one then settles on the server count', () async {
    final emissions = <int>[];
    final subscription = cubit.stream.listen(emissions.add);
    repo.count = 3;
    await cubit.refresh();
    await Future<void>.delayed(Duration.zero);

    repo.count = 4;
    await signals.start('guest');
    signals.emit(
      const NotificationSignal(
        id: 's1',
        typeKey: 'booking.confirmed',
        entityType: 'booking',
        entityId: _uuid,
      ),
    );
    await _flush();
    await subscription.cancel();

    // 3 (refresh) → 4 (optimistic +1) → 4 (server refresh agrees).
    expect(emissions, [3, 4]);
    expect(cubit.state, 4);
    await signals.stop();
  });

  test('a server failure keeps the optimistic bump', () async {
    repo.count = 3;
    await cubit.refresh();
    repo.nextCountError = const AppFailure(
      ApiError(code: ErrorCode.network, messageKey: ''),
    );
    await signals.start('guest');
    signals.emit(
      const NotificationSignal(
        id: 's2',
        typeKey: 'booking.confirmed',
        entityType: 'booking',
        entityId: _uuid,
      ),
    );
    await _flush();
    expect(cubit.state, 4, reason: 'the optimistic count stands');
    await signals.stop();
  });

  test('markedRead subtracts but never goes below zero', () async {
    repo.count = 3;
    await cubit.refresh();
    cubit.markedRead(2);
    expect(cubit.state, 1);
    cubit.markedRead(5);
    expect(cubit.state, 0);
  });

  test('reset clears the count on sign-out', () async {
    repo.count = 7;
    await cubit.refresh();
    cubit.reset();
    expect(cubit.state, 0);
  });
}

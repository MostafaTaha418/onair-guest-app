import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/features/notifications/domain/app_notification.dart';
import 'package:on_air/features/notifications/domain/notifications_repository.dart';
import 'package:on_air/features/notifications/presentation/notifications_cubit.dart';
import 'package:on_air/features/notifications/presentation/unread_count_cubit.dart';

import '../../helpers/fake_connectivity.dart';

/// Serves queued pages and records every call.
final class ScriptedNotifications implements NotificationsRepository {
  final List<List<AppNotification>> pages = [];
  final List<DateTime?> listCalls = [];
  AppFailure? nextMarkReadError;
  final List<List<String>?> markReadCalls = [];
  int unreadCountValue = 0;

  @override
  Future<List<AppNotification>> list({DateTime? before, int limit = 30}) async {
    listCalls.add(before);
    if (pages.isEmpty) return const [];
    return pages.removeAt(0);
  }

  @override
  Future<int> unreadCount() async => unreadCountValue;

  @override
  Future<void> markRead(List<String>? ids) async {
    final error = nextMarkReadError;
    if (error != null) {
      nextMarkReadError = null;
      throw error;
    }
    markReadCalls.add(ids);
  }
}

AppNotification _notification(
  String id, {
  String typeKey = 'booking.confirmed',
  bool read = false,
  String createdAt = '2026-10-28T09:00:00Z',
  String entityId = 'b0000000-0000-4000-8000-000000000001',
}) => AppNotification.fromJson({
  'id': id,
  'type_key': typeKey,
  'category': 'booking',
  'entity_type': 'booking',
  'entity_id': entityId,
  'params': const <String, dynamic>{},
  'read_at': read ? '2026-10-29T10:00:00Z' : null,
  'created_at': createdAt,
});

const _uuid = 'b0000000-0000-4000-8000-000000000001';

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  late ScriptedNotifications repo;
  late ControllableNotificationSignalSource signals;
  late FakeConnectivity connectivity;
  late UnreadCountCubit unread;

  setUp(() {
    repo = ScriptedNotifications();
    signals = ControllableNotificationSignalSource();
    connectivity = FakeConnectivity();
    unread = UnreadCountCubit(notifications: repo, signals: signals);
  });

  tearDown(() async {
    await unread.close();
    connectivity.dispose();
  });

  NotificationsCubit buildCubit({ConnectivityCubit? connectivityCubit}) =>
      NotificationsCubit(
        notifications: repo,
        signals: signals,
        connectivity: connectivityCubit ?? connectivity.createCubit(),
        unread: unread,
      );

  test('load shows the server page newest first', () async {
    final cubit = buildCubit();
    repo.pages
      ..add([_notification('n2'), _notification('n1', read: true)])
      ..add([]);
    await cubit.load();
    final state = cubit.state;
    expect(state, isA<NotificationsReady>());
    final ready = state as NotificationsReady;
    expect(ready.items.map((n) => n.id).toList(), ['n2', 'n1']);
    expect(ready.hasMore, isFalse);
    await cubit.close();
  });

  test('loadMore asks for the page before the last item', () async {
    final cubit = buildCubit();
    final firstPage = List.generate(
      30,
      (index) => _notification(
        'n$index',
        createdAt: '2026-10-20T00:00:${index.toString().padLeft(2, '0')}Z',
      ),
    );
    final secondPage = List.generate(
      10,
      (index) =>
          _notification('o$index', createdAt: '2026-10-19T00:00:0${index}Z'),
    );
    repo.pages
      ..add(firstPage)
      ..add(secondPage)
      ..add([]);
    await cubit.load();
    expect((cubit.state as NotificationsReady).hasMore, isTrue);

    await cubit.loadMore();
    final ready = cubit.state as NotificationsReady;
    expect(ready.items, hasLength(40));
    expect(ready.hasMore, isFalse);
    expect(ready.loadingMore, isFalse);
    expect(repo.listCalls[1], firstPage.last.createdAt);
    await cubit.close();
  });

  test('open marks read locally, reports to the server, and routes', () async {
    repo.unreadCountValue = 2;
    await unread.refresh();
    expect(unread.state, 2);

    final cubit = buildCubit();
    repo.pages.add([_notification('n2')]);
    await cubit.load();

    final location = await cubit.open(
      (cubit.state as NotificationsReady).items.first,
    );
    expect(location, '/bookings/$_uuid');
    expect(repo.markReadCalls, [
      ['n2'],
    ]);
    expect(
      (cubit.state as NotificationsReady).items.first.isUnread,
      isFalse,
      reason: 'the local mark stands',
    );
    expect(unread.state, 1, reason: 'the live count dropped by one');
    await cubit.close();
  });

  test('a failed mark-read does not undo the navigation result', () async {
    final cubit = buildCubit();
    repo.pages.add([_notification('n3', typeKey: 'support.staff_replied')]);
    await cubit.load();
    repo.nextMarkReadError = const AppFailure(
      ApiError(code: ErrorCode.network, messageKey: ''),
    );

    final location = await cubit.open(
      (cubit.state as NotificationsReady).items.first,
    );
    expect(location, '/support/new');
    expect(
      (cubit.state as NotificationsReady).items.first.isUnread,
      isFalse,
    );
    await cubit.close();
  });

  test('markAllRead marks every item and reports all', () async {
    repo.unreadCountValue = 2;
    await unread.refresh();
    final cubit = buildCubit();
    repo.pages.add([
      _notification('n1'),
      _notification('n2'),
      _notification('n3', read: true),
    ]);
    await cubit.load();

    await cubit.markAllRead();
    expect(repo.markReadCalls, [null]);
    expect(
      (cubit.state as NotificationsReady).items.every((n) => !n.isUnread),
      isTrue,
    );
    expect(unread.state, 0);
    await cubit.close();
  });

  test('a signal reloads the first page', () async {
    final cubit = buildCubit();
    repo.pages.add([_notification('n1')]);
    await cubit.load();

    await signals.start('guest');
    repo.pages.add([_notification('n9'), _notification('n8')]);
    signals.emit(
      const NotificationSignal(
        id: 's1',
        typeKey: 'booking.confirmed',
        entityType: 'booking',
        entityId: _uuid,
      ),
    );
    await _flush();

    final ready = cubit.state as NotificationsReady;
    expect(ready.items.map((n) => n.id).toList(), ['n9', 'n8']);
    expect(repo.listCalls.last, isNull, reason: 'a fresh first page');
    await cubit.close();
    await signals.stop();
  });

  test('offline stays offline', () async {
    // One shared cubit: a broadcast flip is never replayed to a later
    // subscriber.
    final conn = connectivity.createCubit();
    connectivity.goOffline();
    await _flush();
    final cubit = buildCubit(connectivityCubit: conn);
    await cubit.load();
    expect(cubit.state, isA<NotificationsOffline>());
    await cubit.close();
    await conn.close();
  });
}

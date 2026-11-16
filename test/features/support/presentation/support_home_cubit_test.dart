import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/features/support/presentation/home/support_home_cubit.dart';

import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_support_repository.dart';

void main() {
  late FakeSupportRepository repository;
  late ControllableNotificationSignalSource signals;
  late FakeConnectivity connectivity;
  late SupportHomeCubit cubit;

  setUp(() async {
    repository = FakeSupportRepository();
    signals = ControllableNotificationSignalSource();
    await signals.start('guest');
    connectivity = FakeConnectivity();
    cubit = SupportHomeCubit(
      repository: repository,
      signals: signals,
      connection: connectivity.createCubit(),
    );
  });

  tearDown(() async {
    await cubit.close();
    connectivity.dispose();
  });

  test('loading becomes ready with cases and cursor', () async {
    repository.pages.add(
      CasePage(items: [sampleSupportCase()], nextCursor: 'next'),
    );
    await cubit.load();
    final state = cubit.state as SupportHomeReady;
    expect(state.items.single.code, 'SC-1042');
    expect(state.hasMore, isTrue);
  });

  test('empty page becomes the empty state', () async {
    repository.pages.add(const CasePage(items: [], nextCursor: null));
    await cubit.load();
    expect(cubit.state, isA<SupportHomeEmpty>());
  });

  test('error keeps the request reference', () async {
    repository.nextError = AppFailure(
      ErrorMapper.fromCode('INTERNAL', requestId: 'req-1'),
    );
    await cubit.load();
    expect(
      (cubit.state as SupportHomeFailed).error.requestId,
      'req-1',
    );
  });

  test('offline keeps the current list and marks it offline', () async {
    repository.pages.add(
      CasePage(items: [sampleSupportCase()], nextCursor: null),
    );
    await cubit.load();
    connectivity.goOffline();
    await Future<void>.delayed(Duration.zero);
    expect((cubit.state as SupportHomeReady).offline, isTrue);
  });

  test('loadMore appends and stops at a null cursor', () async {
    repository.pages
      ..add(CasePage(items: [sampleSupportCase()], nextCursor: 'next'))
      ..add(
        CasePage(
          items: [
            sampleSupportCase(
              id: 'c0000000-0000-4000-8000-000000000002',
            ),
          ],
          nextCursor: null,
        ),
      );
    await cubit.load();
    await cubit.loadMore();
    await cubit.loadMore();
    expect((cubit.state as SupportHomeReady).items, hasLength(2));
    expect(repository.listCursors, [null, 'next']);
  });

  test('staff reply signal refreshes the first page exactly once', () async {
    repository.pages
      ..add(CasePage(items: [sampleSupportCase()], nextCursor: null))
      ..add(CasePage(items: [sampleSupportCase()], nextCursor: null));
    await cubit.load();
    signals.emit(
      const NotificationSignal(
        id: 'n1',
        typeKey: 'support.staff_replied',
        entityType: 'support_case',
        entityId: 'c0000000-0000-4000-8000-000000000001',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(repository.listCursors, [null, null]);
  });
}

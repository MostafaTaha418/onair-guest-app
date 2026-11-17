import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/account/domain/active_session.dart';
import 'package:on_air/features/account/presentation/security/security_cubit.dart';

class _Repository extends Fake implements AccountRepository {
  final sessions = <ActiveSession>[
    ActiveSession(
      id: 'current',
      deviceLabel: 'Current',
      platform: SessionPlatform.android,
      createdAt: DateTime.utc(2026),
      lastActiveAt: DateTime.utc(2026, 11, 17),
      isCurrent: true,
    ),
    ActiveSession(
      id: 'other',
      deviceLabel: 'Other',
      platform: SessionPlatform.ios,
      createdAt: DateTime.utc(2026),
      lastActiveAt: DateTime.utc(2026, 11, 16),
      isCurrent: false,
    ),
  ];
  int endCalls = 0;
  int endAllCalls = 0;
  Completer<void>? pending;
  AppFailure? failure;
  // Per-id gates and failures for concurrent-end scenarios.
  final holds = <String, Completer<void>>{};
  final failures = <String, AppFailure>{};

  @override
  Future<List<ActiveSession>> listSessions() async => List.of(sessions);

  @override
  Future<void> endSession(String id) async {
    endCalls++;
    final hold = holds[id];
    if (hold != null) await hold.future;
    if (failure case final value?) throw value;
    final idFailure = failures[id];
    if (idFailure != null) throw idFailure;
    sessions.removeWhere((session) => session.id == id);
  }

  @override
  Future<void> endOtherSessions() async {
    endAllCalls++;
    await pending?.future;
    sessions.removeWhere((session) => !session.isCurrent);
  }
}

void main() {
  test('load, ending one and end-all expose their in-flight states', () async {
    final repository = _Repository();
    final cubit = SecurityCubit(repository);
    addTearDown(cubit.close);
    await cubit.load();
    expect((cubit.state as SecurityReady).sessions, hasLength(2));

    repository.pending = Completer<void>();
    final ending = cubit.endSession('other');
    expect((cubit.state as SecurityReady).ending, {'other'});
    await cubit.endSession('other');
    expect(repository.endCalls, 1);
    repository.pending!.complete();
    await ending;
    expect((cubit.state as SecurityReady).sessions, hasLength(1));
  });

  test('failure restores the row and keeps an inline error', () async {
    final repository = _Repository()
      ..failure = const AppFailure(
        ApiError(code: ErrorCode.network, messageKey: 'errorNoConnection'),
      );
    final cubit = SecurityCubit(repository);
    addTearDown(cubit.close);
    await cubit.load();
    await cubit.endSession('other');
    final state = cubit.state as SecurityReady;
    expect(state.sessions, hasLength(2));
    expect(state.error?.code, ErrorCode.network);
  });

  test(
    'end all double tap makes one call and leaves the current session',
    () async {
      final repository = _Repository()..pending = Completer<void>();
      final cubit = SecurityCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      final first = cubit.endOtherSessions();
      await cubit.endOtherSessions();
      expect(repository.endAllCalls, 1);
      expect((cubit.state as SecurityReady).endingAll, isTrue);
      repository.pending!.complete();
      await first;
      expect((cubit.state as SecurityReady).sessions.single.isCurrent, isTrue);
    },
  );

  test(
    'two concurrent ends keep their in-flight marks and never resurrect rows',
    () async {
      final repository = _Repository();
      repository.sessions.add(
        ActiveSession(
          id: 'b',
          deviceLabel: 'Second',
          platform: SessionPlatform.ios,
          createdAt: DateTime.utc(2026),
          lastActiveAt: DateTime.utc(2026, 11, 15),
          isCurrent: false,
        ),
      );
      repository.holds
        ..['other'] = Completer<void>()
        ..['b'] = Completer<void>();
      final cubit = SecurityCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();

      final endingA = cubit.endSession('other');
      final endingB = cubit.endSession('b');
      expect((cubit.state as SecurityReady).ending, {'other', 'b'});

      repository.holds['other']!.complete();
      await endingA;
      // B is still in flight: its mark must survive A's settlement.
      expect((cubit.state as SecurityReady).ending, {'b'});

      repository.holds['b']!.complete();
      await endingB;
      final fresh = cubit.state as SecurityReady;
      expect(
        fresh.sessions.map((session) => session.id),
        ['current'],
      );
      expect(fresh.ending, isEmpty);
    },
  );

  test(
    'a failed end keeps its row and the error while another settles',
    () async {
      final repository = _Repository();
      repository.sessions.add(
        ActiveSession(
          id: 'b',
          deviceLabel: 'Second',
          platform: SessionPlatform.ios,
          createdAt: DateTime.utc(2026),
          lastActiveAt: DateTime.utc(2026, 11, 15),
          isCurrent: false,
        ),
      );
      repository.holds
        ..['other'] = Completer<void>()
        ..['b'] = Completer<void>();
      repository.failures['other'] = const AppFailure(
        ApiError(code: ErrorCode.network, messageKey: 'errorNoConnection'),
      );
      final cubit = SecurityCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();

      final endingA = cubit.endSession('other');
      final endingB = cubit.endSession('b');
      repository.holds['other']!.complete();
      await endingA;

      var fresh = cubit.state as SecurityReady;
      // B is still in flight; A failed and keeps its row and the error.
      expect(fresh.ending, {'b'});
      expect(
        fresh.sessions.map((session) => session.id),
        containsAll(['other', 'b']),
      );
      expect(fresh.error?.code, ErrorCode.network);

      repository.holds['b']!.complete();
      await endingB;
      fresh = cubit.state as SecurityReady;
      expect(
        fresh.sessions.map((session) => session.id),
        isNot(contains('b')),
      );
      expect(fresh.sessions.map((session) => session.id), contains('other'));
      expect(fresh.ending, isEmpty);
    },
  );
}

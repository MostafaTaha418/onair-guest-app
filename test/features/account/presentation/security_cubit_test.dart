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

  @override
  Future<List<ActiveSession>> listSessions() async => List.of(sessions);

  @override
  Future<void> endSession(String id) async {
    endCalls++;
    await pending?.future;
    if (failure case final value?) throw value;
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
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/account/domain/notification_preference.dart';
import 'package:on_air/features/account/presentation/notifications/preferences_cubit.dart';

class _Repository extends Fake implements AccountRepository {
  List<NotificationPreference> result = [_support(), _booking()];
  final calls =
      <({String category, NotificationChannel channel, bool enabled})>[];
  final pending = <Completer<void>>[];
  AppFailure? failure;

  @override
  Future<List<NotificationPreference>> getPreferences() async => result;

  @override
  Future<void> setPreference(
    String category,
    NotificationChannel channel,
    bool enabled,
  ) async {
    calls.add((category: category, channel: channel, enabled: enabled));
    if (pending.isNotEmpty) await pending.removeAt(0).future;
    final currentFailure = failure;
    failure = null;
    if (currentFailure != null) throw currentFailure;
  }
}

NotificationPreference _support({bool push = true}) => NotificationPreference(
  key: 'support',
  labelKey: 'notifCategorySupport',
  isMandatory: false,
  channels: {
    NotificationChannel.push: PreferenceChannel(enabled: push),
    NotificationChannel.email: const PreferenceChannel(enabled: true),
  },
);

NotificationPreference _booking() => const NotificationPreference(
  key: 'booking',
  labelKey: 'notifCategoryBooking',
  isMandatory: true,
  channels: {
    NotificationChannel.push: PreferenceChannel(enabled: true),
    NotificationChannel.email: PreferenceChannel(enabled: true),
  },
);

void main() {
  test('load reaches ready and reads the device permission state', () async {
    final repository = _Repository();
    final cubit = PreferencesCubit(
      repository,
      deviceNotificationsBlocked: () async => true,
    );
    addTearDown(cubit.close);

    await cubit.load();
    final state = cubit.state as PreferencesReady;
    expect(state.preferences, hasLength(2));
    expect(state.deviceNotificationsBlocked, isTrue);
  });

  test('toggle is optimistic then confirmed', () async {
    final repository = _Repository();
    final completer = Completer<void>();
    repository.pending.add(completer);
    final cubit = PreferencesCubit.seeded(
      repository,
      PreferencesReady(
        preferences: repository.result,
        deviceNotificationsBlocked: false,
      ),
    );
    addTearDown(cubit.close);

    final future = cubit.toggle('support', NotificationChannel.push, false);
    var state = cubit.state as PreferencesReady;
    expect(
      state.preference('support')!.enabled(NotificationChannel.push),
      isFalse,
    );
    expect(
      state.saving,
      contains(const PreferenceKey('support', NotificationChannel.push)),
    );
    completer.complete();
    await future;
    state = cubit.state as PreferencesReady;
    expect(state.saving, isEmpty);
  });

  test('failure reverts and exposes a retry event', () async {
    final repository = _Repository()
      ..failure = AppFailure(ErrorMapper.noResponse());
    final cubit = PreferencesCubit.seeded(
      repository,
      PreferencesReady(
        preferences: repository.result,
        deviceNotificationsBlocked: false,
      ),
    );
    addTearDown(cubit.close);

    await cubit.toggle('support', NotificationChannel.push, false);
    final state = cubit.state as PreferencesReady;
    expect(
      state.preference('support')!.enabled(NotificationChannel.push),
      isTrue,
    );
    expect(state.failure?.enabled, isFalse);
    expect(state.failure?.error.code, ErrorCode.network);
    await cubit.retryFailure();
    expect(repository.calls, hasLength(2));
  });

  test('mandatory toggles never reach the repository', () async {
    final repository = _Repository();
    final cubit = PreferencesCubit.seeded(
      repository,
      PreferencesReady(
        preferences: repository.result,
        deviceNotificationsBlocked: false,
      ),
    );
    addTearDown(cubit.close);
    await cubit.toggle('booking', NotificationChannel.push, false);
    expect(repository.calls, isEmpty);
  });

  test(
    'rapid toggles coalesce to the final value after the active save',
    () async {
      final repository = _Repository();
      final first = Completer<void>();
      repository.pending.add(first);
      final cubit = PreferencesCubit.seeded(
        repository,
        PreferencesReady(
          preferences: repository.result,
          deviceNotificationsBlocked: false,
        ),
      );
      addTearDown(cubit.close);

      final active = cubit.toggle('support', NotificationChannel.push, false);
      unawaited(cubit.toggle('support', NotificationChannel.push, true));
      unawaited(cubit.toggle('support', NotificationChannel.push, false));
      unawaited(cubit.toggle('support', NotificationChannel.push, true));
      expect(repository.calls, hasLength(1));
      first.complete();
      await active;
      await Future<void>.delayed(Duration.zero);
      expect(repository.calls.map((call) => call.enabled), [false, true]);
    },
  );
}

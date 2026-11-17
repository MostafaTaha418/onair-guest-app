import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/account/domain/notification_preference.dart';

sealed class PreferencesState {
  const PreferencesState();
}

final class PreferencesLoading extends PreferencesState {
  const PreferencesLoading();
}

final class PreferencesFailed extends PreferencesState {
  const PreferencesFailed(this.error);
  final ApiError error;
}

@immutable
final class PreferenceKey {
  const PreferenceKey(this.category, this.channel);
  final String category;
  final NotificationChannel channel;

  @override
  bool operator ==(Object other) =>
      other is PreferenceKey &&
      category == other.category &&
      channel == other.channel;

  @override
  int get hashCode => Object.hash(category, channel);
}

final class PreferenceSaveFailure {
  const PreferenceSaveFailure({
    required this.key,
    required this.enabled,
    required this.error,
  });
  final PreferenceKey key;
  final bool enabled;
  final ApiError error;
}

final class PreferencesReady extends PreferencesState {
  const PreferencesReady({
    required this.preferences,
    required this.deviceNotificationsBlocked,
    this.saving = const {},
    this.failure,
  });

  final List<NotificationPreference> preferences;
  final bool deviceNotificationsBlocked;
  final Set<PreferenceKey> saving;
  final PreferenceSaveFailure? failure;

  NotificationPreference? preference(String category) {
    for (final preference in preferences) {
      if (preference.key == category) return preference;
    }
    return null;
  }

  PreferencesReady copyWith({
    List<NotificationPreference>? preferences,
    bool? deviceNotificationsBlocked,
    Set<PreferenceKey>? saving,
    PreferenceSaveFailure? failure,
    bool clearFailure = false,
  }) => PreferencesReady(
    preferences: preferences ?? this.preferences,
    deviceNotificationsBlocked:
        deviceNotificationsBlocked ?? this.deviceNotificationsBlocked,
    saving: saving ?? this.saving,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

final class PreferencesCubit extends Cubit<PreferencesState> {
  PreferencesCubit(
    this._repository, {
    required this._deviceNotificationsBlocked,
  }) : super(const PreferencesLoading());

  PreferencesCubit.seeded(this._repository, PreferencesReady state)
    : _deviceNotificationsBlocked = (() async => false),
      super(state);

  final AccountRepository _repository;
  final Future<bool> Function() _deviceNotificationsBlocked;
  final Map<PreferenceKey, bool> _queued = {};

  Future<void> load() async {
    emit(const PreferencesLoading());
    try {
      final results = await Future.wait<Object>([
        _repository.getPreferences(),
        _deviceNotificationsBlocked(),
      ]);
      emit(
        PreferencesReady(
          preferences: results[0] as List<NotificationPreference>,
          deviceNotificationsBlocked: results[1] as bool,
        ),
      );
    } on AppFailure catch (failure) {
      emit(PreferencesFailed(failure.error));
    } on Object {
      emit(PreferencesFailed(ErrorMapper.fromCode('INTERNAL')));
    }
  }

  Future<void> toggle(
    String category,
    NotificationChannel channel,
    // Mirrors the repository wire order and keeps call sites compact.
    // ignore: avoid_positional_boolean_parameters
    bool enabled,
  ) async {
    final ready = state;
    if (ready is! PreferencesReady) return;
    final preference = ready.preference(category);
    if (preference == null || preference.isMandatory) return;
    final key = PreferenceKey(category, channel);
    _replaceValue(ready, key, enabled);
    final current = state as PreferencesReady;
    if (current.saving.contains(key)) {
      _queued[key] = enabled;
      return;
    }
    await _save(key, enabled, preference.enabled(channel));
  }

  Future<void> _save(
    PreferenceKey key,
    bool enabled,
    bool rollback,
  ) async {
    var ready = state as PreferencesReady;
    emit(ready.copyWith(saving: {...ready.saving, key}, clearFailure: true));
    try {
      await _repository.setPreference(key.category, key.channel, enabled);
    } on AppFailure catch (failure) {
      ready = state as PreferencesReady;
      _replaceValue(ready, key, rollback);
      ready = state as PreferencesReady;
      emit(
        ready.copyWith(
          saving: {...ready.saving}..remove(key),
          failure: PreferenceSaveFailure(
            key: key,
            enabled: enabled,
            error: failure.error,
          ),
        ),
      );
      _queued.remove(key);
      return;
    }
    ready = state as PreferencesReady;
    final queued = _queued.remove(key);
    if (queued != null && queued != enabled) {
      await _save(key, queued, enabled);
      return;
    }
    emit(ready.copyWith(saving: {...ready.saving}..remove(key)));
  }

  Future<void> retryFailure() async {
    final ready = state;
    if (ready is! PreferencesReady || ready.failure == null) return;
    final failure = ready.failure!;
    _replaceValue(ready, failure.key, failure.enabled);
    await _save(
      failure.key,
      failure.enabled,
      !failure.enabled,
    );
  }

  void _replaceValue(PreferencesReady ready, PreferenceKey key, bool enabled) {
    emit(
      ready.copyWith(
        preferences: [
          for (final preference in ready.preferences)
            if (preference.key == key.category)
              preference.withChannel(key.channel, enabled: enabled)
            else
              preference,
        ],
        clearFailure: true,
      ),
    );
  }
}

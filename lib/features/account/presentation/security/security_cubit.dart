import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/account/domain/active_session.dart';

sealed class SecurityState {
  const SecurityState();
}

final class SecurityLoading extends SecurityState {
  const SecurityLoading();
}

final class SecurityFailed extends SecurityState {
  const SecurityFailed(this.error);
  final ApiError error;
}

final class SecurityReady extends SecurityState {
  const SecurityReady({
    required this.sessions,
    this.ending = const {},
    this.endingAll = false,
    this.error,
  });

  final List<ActiveSession> sessions;
  final Set<String> ending;
  final bool endingAll;
  final ApiError? error;

  SecurityReady copyWith({
    List<ActiveSession>? sessions,
    Set<String>? ending,
    bool? endingAll,
    ApiError? error,
    bool clearError = false,
  }) => SecurityReady(
    sessions: sessions ?? this.sessions,
    ending: ending ?? this.ending,
    endingAll: endingAll ?? this.endingAll,
    error: clearError ? null : error ?? this.error,
  );
}

final class SecurityCubit extends Cubit<SecurityState> {
  SecurityCubit(this.repository) : super(const SecurityLoading());

  SecurityCubit.seeded(this.repository, SecurityState state) : super(state);

  final AccountRepository repository;
  bool _loading = false;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    emit(const SecurityLoading());
    try {
      final sessions = await repository.listSessions();
      if (!isClosed) emit(SecurityReady(sessions: sessions));
    } on AppFailure catch (failure) {
      if (!isClosed) emit(SecurityFailed(failure.error));
    } finally {
      _loading = false;
    }
  }

  Future<void> endSession(String id) async {
    final current = state;
    if (current is! SecurityReady ||
        current.endingAll ||
        current.ending.contains(id)) {
      return;
    }
    final session = current.sessions.where((item) => item.id == id).firstOrNull;
    if (session == null || session.isCurrent) return;
    emit(current.copyWith(ending: {...current.ending, id}, clearError: true));
    try {
      await repository.endSession(id);
      if (!isClosed) {
        emit(
          current.copyWith(
            sessions: current.sessions.where((item) => item.id != id).toList(),
            ending: const {},
            clearError: true,
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(current.copyWith(ending: const {}, error: failure.error));
      }
    }
  }

  Future<void> endOtherSessions() async {
    final current = state;
    if (current is! SecurityReady ||
        current.endingAll ||
        current.ending.isNotEmpty) {
      return;
    }
    emit(current.copyWith(endingAll: true, clearError: true));
    try {
      await repository.endOtherSessions();
      if (!isClosed) {
        emit(
          current.copyWith(
            sessions: current.sessions.where((item) => item.isCurrent).toList(),
            endingAll: false,
            clearError: true,
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(current.copyWith(endingAll: false, error: failure.error));
      }
    }
  }
}

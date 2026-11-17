import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/features/support/domain/support_repository.dart';

sealed class SupportHomeState {
  const SupportHomeState();
}

final class SupportHomeLoading extends SupportHomeState {
  const SupportHomeLoading();
}

final class SupportHomeReady extends SupportHomeState {
  const SupportHomeReady({
    required this.items,
    required this.nextCursor,
    this.loadingMore = false,
    this.offline = false,
  });

  final List<SupportCase> items;
  final String? nextCursor;
  final bool loadingMore;
  final bool offline;
  bool get hasMore => nextCursor != null;

  SupportHomeReady copyWith({
    List<SupportCase>? items,
    String? nextCursor,
    bool clearCursor = false,
    bool? loadingMore,
    bool? offline,
  }) => SupportHomeReady(
    items: items ?? this.items,
    nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    loadingMore: loadingMore ?? this.loadingMore,
    offline: offline ?? this.offline,
  );
}

final class SupportHomeEmpty extends SupportHomeState {
  const SupportHomeEmpty({this.offline = false});
  final bool offline;
}

final class SupportHomeFailed extends SupportHomeState {
  const SupportHomeFailed(this.error);
  final ApiError error;
}

final class SupportHomeCubit extends Cubit<SupportHomeState> {
  SupportHomeCubit({
    required this.repository,
    required NotificationSignalSource signals,
    required ConnectivityCubit connection,
  }) : connectivity = connection,
       super(const SupportHomeLoading()) {
    _signalSubscription = signals.signals
        .where((signal) => signal.typeKey == 'support.staff_replied')
        .listen((_) => unawaited(refresh(silent: true)));
    _connectivitySubscription = connection.stream.listen(_onConnectivity);
  }

  SupportHomeCubit.seeded({
    required this.repository,
    required SupportHomeState state,
  }) : connectivity = null,
       super(state);

  final SupportRepository repository;
  final ConnectivityCubit? connectivity;
  StreamSubscription<NotificationSignal>? _signalSubscription;
  StreamSubscription<ConnectivityState>? _connectivitySubscription;
  bool _busy = false;

  Future<void> load() => refresh();

  Future<void> refresh({bool silent = false}) async {
    if (_busy) return;
    _busy = true;
    final previous = state;
    if (!silent) emit(const SupportHomeLoading());
    try {
      if (connectivity?.state.isOnline == false) {
        _markOffline(previous);
        return;
      }
      final page = await repository.listCases();
      if (isClosed) return;
      if (page.items.isEmpty) {
        emit(const SupportHomeEmpty());
      } else {
        emit(
          SupportHomeReady(
            items: page.items,
            nextCursor: page.nextCursor,
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (isClosed) return;
      if (failure.error.code == ErrorCode.network &&
          previous is SupportHomeReady) {
        emit(previous.copyWith(offline: true));
      } else {
        emit(SupportHomeFailed(failure.error));
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (_busy ||
        current is! SupportHomeReady ||
        !current.hasMore ||
        current.offline) {
      return;
    }
    _busy = true;
    emit(current.copyWith(loadingMore: true));
    try {
      final page = await repository.listCases(cursor: current.nextCursor);
      if (isClosed) return;
      emit(
        SupportHomeReady(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
        ),
      );
    } on AppFailure {
      if (!isClosed) emit(current);
    } finally {
      _busy = false;
    }
  }

  void _onConnectivity(ConnectivityState connectivity) {
    if (isClosed) return;
    final current = state;
    if (!connectivity.isOnline) {
      _markOffline(current);
    } else if (current is SupportHomeReady && current.offline) {
      emit(current.copyWith(offline: false));
      unawaited(refresh(silent: true));
    } else if ((current is SupportHomeEmpty && current.offline) ||
        (current is SupportHomeFailed &&
            current.error.code == ErrorCode.network)) {
      // Nothing on screen worth preserving: an offline «empty» screen or
      // a failed network load retries visibly (Loading → content) on the
      // first reconnect, while the Ready list above stays put with a
      // silent refresh.
      unawaited(refresh());
    }
  }

  void _markOffline(SupportHomeState previous) {
    if (previous is SupportHomeReady) {
      emit(previous.copyWith(offline: true, loadingMore: false));
    } else if (previous is SupportHomeEmpty) {
      emit(const SupportHomeEmpty(offline: true));
    } else {
      emit(const SupportHomeEmpty(offline: true));
    }
  }

  @override
  Future<void> close() async {
    await _signalSubscription?.cancel();
    await _connectivitySubscription?.cancel();
    await super.close();
  }
}

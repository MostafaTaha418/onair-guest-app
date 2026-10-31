import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/app/router/notification_router.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/features/notifications/domain/app_notification.dart';
import 'package:on_air/features/notifications/domain/notifications_repository.dart';
import 'package:on_air/features/notifications/presentation/unread_count_cubit.dart';

sealed class NotificationsState {
  const NotificationsState();
}

final class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

final class NotificationsReady extends NotificationsState {
  const NotificationsReady({
    required this.items,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<AppNotification> items;

  /// A page shorter than the 30-item limit means the server is exhausted.
  final bool hasMore;
  final bool loadingMore;
}

final class NotificationsFailed extends NotificationsState {
  const NotificationsFailed(this.error);

  final ApiError error;
}

final class NotificationsOffline extends NotificationsState {
  const NotificationsOffline();
}

/// The notification center (US5): newest-first pages, read marking, and a
/// fresh first page whenever a signal arrives.
final class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required this._notifications,
    required this._signals,
    required this._connectivity,
    required this._unread,
  }) : super(const NotificationsLoading()) {
    _subscription = _signals.signals.listen(
      (_) => unawaited(_reloadFirstPage()),
    );
  }

  static const int _pageLimit = 30;

  final NotificationsRepository _notifications;
  final NotificationSignalSource _signals;
  final ConnectivityCubit _connectivity;
  final UnreadCountCubit _unread;
  StreamSubscription<NotificationSignal>? _subscription;

  bool get _offline => !_connectivity.state.isOnline;

  Future<void> load() async {
    if (_offline) {
      emit(const NotificationsOffline());
      return;
    }
    try {
      final page = await _notifications.list();
      if (isClosed) return;
      emit(
        NotificationsReady(
          items: page,
          hasMore: page.length >= _pageLimit,
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed) return;
      emit(NotificationsFailed(failure.error));
    }
  }

  Future<void> loadMore() async {
    final state = this.state;
    if (state is! NotificationsReady ||
        state.loadingMore ||
        !state.hasMore ||
        state.items.isEmpty) {
      return;
    }
    emit(
      NotificationsReady(
        items: state.items,
        hasMore: state.hasMore,
        loadingMore: true,
      ),
    );
    try {
      final page = await _notifications.list(
        before: state.items.last.createdAt,
      );
      if (isClosed) return;
      emit(
        NotificationsReady(
          items: [...state.items, ...page],
          hasMore: page.length >= _pageLimit,
        ),
      );
    } on AppFailure {
      if (isClosed) return;
      emit(
        NotificationsReady(
          items: state.items,
          hasMore: state.hasMore,
        ),
      );
    }
  }

  /// Marks [notification] read (locally first — a failed server call never
  /// blocks the navigation) and returns the location to open.
  Future<String> open(AppNotification notification) async {
    final wasUnread = notification.isUnread;
    _replace(notification.copyWith(readAt: DateTime.now().toUtc()));
    if (wasUnread) _unread.markedRead(1);
    try {
      await _notifications.markRead([notification.id]);
    } on AppFailure {
      // The local mark stands; the next sync fixes the server side.
    }
    return NotificationRouter.locationFor(
      notification.typeKey,
      notification.entityType,
      notification.entityId,
    );
  }

  Future<void> markAllRead() async {
    final state = this.state;
    if (state is! NotificationsReady) return;
    final unreadCount = state.items.where((n) => n.isUnread).length;
    emit(
      NotificationsReady(
        items: [
          for (final n in state.items)
            n.isUnread ? n.copyWith(readAt: DateTime.now().toUtc()) : n,
        ],
        hasMore: state.hasMore,
      ),
    );
    if (unreadCount > 0) _unread.markedRead(unreadCount);
    try {
      await _notifications.markRead(null);
    } on AppFailure {
      // The local mark stands.
    }
  }

  Future<void> _reloadFirstPage() async {
    if (_offline || isClosed) return;
    try {
      final page = await _notifications.list();
      if (isClosed) return;
      emit(
        NotificationsReady(
          items: page,
          hasMore: page.length >= _pageLimit,
        ),
      );
    } on AppFailure {
      // The shown page stays.
    }
  }

  void _replace(AppNotification updated) {
    final state = this.state;
    if (state is! NotificationsReady) return;
    emit(
      NotificationsReady(
        items: [
          for (final n in state.items) n.id == updated.id ? updated : n,
        ],
        hasMore: state.hasMore,
        loadingMore: state.loadingMore,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}

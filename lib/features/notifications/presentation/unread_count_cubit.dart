import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/features/notifications/domain/notifications_repository.dart';

/// The live unread count behind the home bell (app-scoped, US5).
final class UnreadCountCubit extends Cubit<int> {
  UnreadCountCubit({
    required this._notifications,
    required NotificationSignalSource signals,
  }) : super(0) {
    _subscription = signals.signals.listen((_) {
      if (isClosed) return;
      // Optimistic bump, then the server's own count.
      emit(state + 1);
      unawaited(refresh());
    });
  }

  final NotificationsRepository _notifications;
  StreamSubscription<NotificationSignal>? _subscription;

  /// Reads the server count; errors keep the current value.
  Future<void> refresh() async {
    try {
      final count = await _notifications.unreadCount();
      if (isClosed) return;
      emit(count);
    } on AppFailure {
      // The optimistic or last known count stays.
    }
  }

  /// n items were marked read (never below zero).
  void markedRead(int n) {
    if (isClosed || n <= 0) return;
    emit(state > n ? state - n : 0);
  }

  /// Signed out: nothing is unread.
  void reset() {
    if (isClosed) return;
    emit(0);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}

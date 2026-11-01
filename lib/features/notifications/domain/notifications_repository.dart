import 'package:on_air/features/notifications/domain/app_notification.dart';

/// Reads the guest's notification rows through `common_*` RPCs. Every method
/// throws `AppFailure` on error.
abstract interface class NotificationsRepository {
  /// Newest first, page size 30 (contract D5). [before] is the cursor: rows
  /// older than it.
  Future<List<AppNotification>> list({DateTime? before, int limit = 30});

  Future<int> unreadCount();

  /// Marks [ids] read; `null` means every unread row.
  Future<void> markRead(List<String>? ids);
}

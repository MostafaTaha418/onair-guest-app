import 'package:flutter/foundation.dart';

/// The one-shot `extra` carried on `go(AppRoutes.home)` after a successful
/// deletion (task T070): the home screen renders «حسابك اتحذف» once and the
/// flag never survives another navigation.
@immutable
final class AccountDeletedNotice {
  const AccountDeletedNotice();
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:on_air/core/errors/api_error.dart';

/// Why the server refused the deletion (data-model §6): an active booking,
/// a running refund, or an open damage claim. Anything unknown from the
/// server still shows, as `other`.
enum DeletionBlockerKind { booking, refund, damageClaim, other }

@immutable
final class DeletionBlocker {
  const DeletionBlocker({
    required this.kind,
    required this.id,
    required this.code,
  });

  /// Parses the server's `details.blockers` payload
  /// (`[{kind, id, code}, …]`, contracts U5). An unknown kind is kept as
  /// [DeletionBlockerKind.other] and still listed; empty or missing
  /// blockers yield an empty list.
  static List<DeletionBlocker> fromDetails(Map<String, dynamic>? details) {
    final raw = details?['blockers'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          DeletionBlocker(
            kind: switch (item['kind']) {
              'booking' => DeletionBlockerKind.booking,
              'refund' => DeletionBlockerKind.refund,
              'damage_claim' => DeletionBlockerKind.damageClaim,
              _ => DeletionBlockerKind.other,
            },
            id: item['id'] as String? ?? '',
            code: item['code'] as String? ?? '',
          ),
    ];
  }

  final DeletionBlockerKind kind;
  final String id;
  final String code;

  @override
  bool operator ==(Object other) =>
      other is DeletionBlocker &&
      other.kind == kind &&
      other.id == id &&
      other.code == code;

  @override
  int get hashCode => Object.hash(kind, id, code);
}

/// `ACCOUNT_HAS_ACTIVE_BOOKINGS` with its `details.blockers` — raised by
/// request and re-checked at confirm (contracts U5).
final class DeletionBlockedException implements Exception {
  const DeletionBlockedException(this.blockers);

  final List<DeletionBlocker> blockers;

  /// The equivalent server failure, for flows that surface it as an
  /// [AppFailure] (e.g. a generic error view).
  AppFailure get failure => const AppFailure(
    ApiError(
      code: ErrorCode.accountHasActiveBookings,
      messageKey: 'accountHasActiveBookings',
    ),
  );

  /// Best-effort decoder for a Postgrest `DETAIL` string carrying the
  /// unified `details` JSON (`{code, message_key, details}`).
  static Map<String, dynamic>? parseDetailsJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on Object {
      return null;
    }
  }
}

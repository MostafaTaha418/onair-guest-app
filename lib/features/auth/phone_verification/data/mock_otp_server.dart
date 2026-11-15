import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';

/// The mock OTP limiter (node-otp.md A8 "Processing order" and "Ladder"):
/// the send ladder and the 7-day block over the account, phone and device
/// keys. Mock only (`BACKEND_MODE=mock`) — the real limits live in
/// `private.otp_send_limits`, the display half is [SendWindow].
final class MockOtpServer {
  /// [clock] defaults to [MockBackend.clock], which the integration tests
  /// replace; the unit tests inject their own.
  MockOtpServer({this._clock});

  final DateTime Function()? _clock;
  DateTime Function() get clock => _clock ?? MockBackend.clock;

  /// `APP_ATTESTATION_FAILED` on every send while true — nothing counted,
  /// nothing sent (A8 step 2).
  bool attestationFails = false;

  /// The method names each public call logged, for the tests: `send` marks a
  /// counted send, `send.attestationFailed` a rejected one, `verify` the
  /// success reset.
  final List<String> callLog = [];

  /// `otp_whatsapp_max_sends` (10) — the next request after the 10th send
  /// blocks.
  static const _maxSends = 10;

  /// `otp_whatsapp_block_days` (7).
  static const _blockDays = Duration(days: 7);

  /// `otp_whatsapp_idle_reset_days` (7) — a quiet week clears the counters.
  static const _idleResetDays = Duration(days: 7);

  /// The wait after send *n* (`otp_whatsapp_ladder_seconds`): 30 s, 5 min,
  /// 1 h, 24 h, then 1 h and 24 h alternating.
  static Duration ladder(int sendCount) => switch (sendCount) {
    1 => const Duration(seconds: 30),
    2 => const Duration(minutes: 5),
    3 => const Duration(hours: 1),
    4 => const Duration(hours: 24),
    final n => n.isOdd ? const Duration(hours: 1) : const Duration(hours: 24),
  };

  final Map<String, _KeyRecord> _keys = {};

  _KeyRecord _record(String key) => _keys.putIfAbsent(key, _KeyRecord.new);

  List<_KeyRecord> _records(String accountId, String phone, String deviceId) =>
      [
        _record('acct:$accountId'),
        _record('phone:$phone'),
        _record('dev:$deviceId'),
      ];

  /// The send attempt of one challenge recipient (A8 steps 2–8): throws the
  /// mapped [AppFailure] or returns the window the counters produced.
  SendWindow send({
    required String accountId,
    required String phone,
    required String deviceId,
  }) {
    if (attestationFails) {
      callLog.add('send.attestationFailed');
      throw AppFailure(ErrorMapper.fromCode('APP_ATTESTATION_FAILED'));
    }
    callLog.add('send');
    final now = clock();
    final records = _records(accountId, phone, deviceId);
    for (final record in records) {
      final lastSendAt = record.lastSendAt;
      if (lastSendAt == null) continue;
      final blocked = record.blockedUntil;
      final unblocked = blocked == null || !blocked.isAfter(now);
      // Idle reset: a quiet week clears the counters (blocks not reached).
      if (unblocked && now.difference(lastSendAt) >= _idleResetDays) {
        record.resetCounters();
      }
    }
    final blockedUntil = _strictest(
      records.map((record) => record.blockedUntil),
    );
    if (blockedUntil != null && blockedUntil.isAfter(now)) {
      throw _blockedError(blockedUntil, now);
    }
    final sends = records.fold(
      0,
      (max, record) => record.sendCount > max ? record.sendCount : max,
    );
    if (sends >= _maxSends) {
      // The block lands on all three keys together (A8 step 5).
      final until = now.add(_blockDays);
      for (final record in records) {
        record.blockedUntil = until;
      }
      throw _blockedError(until, now);
    }
    final nextSendAt = _strictest(records.map((record) => record.nextSendAt));
    if (nextSendAt != null && nextSendAt.isAfter(now)) {
      throw _rateLimitedError(nextSendAt, now);
    }
    // Step 8: every key counts the send and moves down the ladder.
    var wait = Duration.zero;
    for (final record in records) {
      record
        ..sendCount += 1
        ..lastSendAt = now
        ..nextSendAt = now.add(MockOtpServer.ladder(record.sendCount));
      wait = MockOtpServer.ladder(record.sendCount);
    }
    return SendWindow(
      serverTime: now,
      receivedAt: now,
      nextSendAt: now.add(wait),
    );
  }

  /// The window the three keys of [accountId]/[phone]/[deviceId] currently
  /// impose — what `common_get_otp_status` (A7) would answer.
  SendWindow windowOf({
    required String accountId,
    required String phone,
    required String deviceId,
  }) {
    final now = clock();
    final records = _records(accountId, phone, deviceId);
    final blockedUntil = _strictest(
      records.map((record) => record.blockedUntil),
    );
    return SendWindow(
      serverTime: now,
      receivedAt: now,
      nextSendAt: _strictest(records.map((record) => record.nextSendAt)),
      blockedUntil: blockedUntil != null && blockedUntil.isAfter(now)
          ? blockedUntil
          : null,
    );
  }

  /// The success reset (`common_verify_otp`, A5/A6): the three keys of the
  /// last send go back to zero; blocks are not reset, they expire.
  void countSuccess({
    required String accountId,
    required String phone,
    required String deviceId,
  }) {
    callLog.add('verify');
    for (final record in _records(accountId, phone, deviceId)) {
      record.resetCounters();
    }
  }

  /// The counters of one `acct:`/`phone:`/`dev:` key, for the tests.
  ({
    int sendCount,
    DateTime? lastSendAt,
    DateTime? nextSendAt,
    DateTime? blockedUntil,
  })
  counters(String key) {
    final record = _record(key);
    return (
      sendCount: record.sendCount,
      lastSendAt: record.lastSendAt,
      nextSendAt: record.nextSendAt,
      blockedUntil: record.blockedUntil,
    );
  }

  static DateTime? _strictest(Iterable<DateTime?> values) =>
      values.nonNulls.fold<DateTime?>(
        null,
        (max, value) => max == null || value.isAfter(max) ? value : max,
      );

  static AppFailure _blockedError(DateTime blockedUntil, DateTime now) =>
      AppFailure(
        _withDetails(ErrorMapper.fromCode('OTP_SEND_BLOCKED'), {
          'blocked_until': blockedUntil.toUtc().toIso8601String(),
          'server_time': now.toUtc().toIso8601String(),
        }),
      );

  static AppFailure _rateLimitedError(DateTime nextSendAt, DateTime now) =>
      AppFailure(
        _withDetails(ErrorMapper.fromCode('RATE_LIMITED'), {
          'next_send_at': nextSendAt.toUtc().toIso8601String(),
          'server_time': now.toUtc().toIso8601String(),
        }),
      );

  static ApiError _withDetails(ApiError error, Map<String, dynamic> details) =>
      ApiError(
        code: error.code,
        messageKey: error.messageKey,
        details: details,
      );
}

/// The mutable counters of one limit key — the mock's row of
/// `private.otp_send_limits` without the HMAC.
final class _KeyRecord {
  int sendCount = 0;
  DateTime? lastSendAt;
  DateTime? nextSendAt;
  DateTime? blockedUntil;

  void resetCounters() {
    sendCount = 0;
    nextSendAt = null;
  }
}

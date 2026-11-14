import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/features/auth/phone_verification/presentation/widgets/send_window_notice.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// T061 — the display half of the ladder (R8): `mm:ss` under the hour,
/// hours+minutes from it, and the countdown that ignores a skewed device
/// clock because it subtracts the server's offset.
void main() {
  final l10n = lookupAppLocalizations(const Locale('ar'));

  group('formatSendWait', () {
    test('renders mm:ss under one hour', () {
      expect(formatSendWait(const Duration(seconds: 30), l10n), '00:30');
      expect(
        formatSendWait(
          const Duration(hours: 1) - const Duration(seconds: 1),
          l10n,
        ),
        '59:59',
      );
      expect(
        formatSendWait(const Duration(minutes: 4, seconds: 59), l10n),
        '04:59',
      );
    });

    test('renders hours and minutes from one hour up', () {
      expect(
        formatSendWait(const Duration(hours: 1), l10n),
        l10n.durationHoursMinutes('1', '0'),
      );
      expect(
        formatSendWait(const Duration(hours: 23, minutes: 10), l10n),
        l10n.durationHoursMinutes('23', '10'),
      );
      expect(
        formatSendWait(const Duration(hours: 24), l10n),
        l10n.durationHoursMinutes('24', '0'),
      );
    });

    test('clamps a negative remainder to zero', () {
      expect(formatSendWait(const Duration(seconds: -3), l10n), '00:00');
    });
  });

  group('remainingUntilSend', () {
    final serverNow = DateTime.utc(2026, 11, 14, 10);
    final nextSendAt = serverNow.add(const Duration(minutes: 10));

    test('uses the server difference, not the skewed device clock', () {
      final window = SendWindow(
        serverTime: serverNow,
        nextSendAt: nextSendAt,
      );
      // The device runs 10 minutes behind the server (R8): the remaining
      // time still equals the server difference.
      final deviceNow = serverNow.subtract(const Duration(minutes: 10));
      expect(
        window.remainingUntilSend(deviceNow),
        const Duration(minutes: 10),
      );
    });

    test('is a fixed server fact: the device clock never moves it', () {
      final window = SendWindow(
        serverTime: serverNow,
        nextSendAt: nextSendAt,
      );
      // Any device clock answers with the same server difference; the
      // ticking time comes from the caller's own elapsed measurement.
      expect(
        window.remainingUntilSend(serverNow.subtract(const Duration(hours: 5))),
        const Duration(minutes: 10),
      );
      expect(
        window.remainingUntilSend(serverNow.add(const Duration(hours: 5))),
        const Duration(minutes: 10),
      );
      expect(
        SendWindow(
          serverTime: serverNow,
          nextSendAt: serverNow,
        ).remainingUntilSend(serverNow),
        Duration.zero,
      );
      expect(
        SendWindow(
          serverTime: serverNow,
          nextSendAt: serverNow.subtract(const Duration(minutes: 1)),
        ).remainingUntilSend(serverNow),
        Duration.zero,
        reason: 'a stale window never waits',
      );
      expect(
        SendWindow(serverTime: serverNow).remainingUntilSend(serverNow),
        Duration.zero,
        reason: 'a null nextSendAt never waits',
      );
    });
  });
}

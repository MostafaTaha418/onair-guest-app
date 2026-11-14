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

    test('uses the server difference captured at arrival', () {
      // The device runs 10 minutes behind the server when the response
      // arrives: receivedAt 09:50, serverTime 10:00.
      final window = SendWindow(
        serverTime: serverNow,
        receivedAt: serverNow.subtract(const Duration(minutes: 10)),
        nextSendAt: nextSendAt,
      );
      // Right at arrival the remaining time equals the server difference.
      expect(
        window.remainingUntilSend(
          serverNow.subtract(const Duration(minutes: 10)),
        ),
        const Duration(minutes: 10),
      );
    });

    test('decreases with real elapsed time, immune to the clock skew', () {
      final window = SendWindow(
        serverTime: serverNow,
        receivedAt: serverNow.subtract(const Duration(minutes: 10)),
        nextSendAt: nextSendAt,
      );
      // Five real minutes later the server clock has moved the same five
      // minutes: 10 m − 5 m. A skewed device clock only shifts the labels —
      // receivedAt and deviceNow come from the same clock.
      final deviceNow = serverNow.subtract(const Duration(minutes: 5));
      expect(window.remainingUntilSend(deviceNow), const Duration(minutes: 5));
      // A device running 10 minutes AHEAD measures the same elapsed time.
      final skewedNow = deviceNow.add(const Duration(minutes: 10));
      final skewedReceived = skewedNow.subtract(const Duration(minutes: 5));
      expect(
        SendWindow(
          serverTime: serverNow,
          receivedAt: skewedReceived,
          nextSendAt: nextSendAt,
        ).remainingUntilSend(skewedNow),
        const Duration(minutes: 5),
      );
    });

    test('is zero once the window passed on the server clock', () {
      final window = SendWindow(
        serverTime: serverNow,
        receivedAt: serverNow,
        nextSendAt: nextSendAt,
      );
      // Eleven real minutes after arrival the server clock passed
      // next_send_at.
      expect(
        window.remainingUntilSend(serverNow.add(const Duration(minutes: 11))),
        Duration.zero,
      );
      expect(
        SendWindow(
          serverTime: serverNow,
          receivedAt: serverNow,
          nextSendAt: serverNow,
        ).remainingUntilSend(serverNow),
        Duration.zero,
      );
      expect(
        SendWindow(
          serverTime: serverNow,
          receivedAt: serverNow,
          nextSendAt: serverNow.subtract(const Duration(minutes: 1)),
        ).remainingUntilSend(serverNow),
        Duration.zero,
        reason: 'a stale window never waits',
      );
      expect(
        SendWindow(
          serverTime: serverNow,
          receivedAt: serverNow,
        ).remainingUntilSend(serverNow),
        Duration.zero,
        reason: 'a null nextSendAt never waits',
      );
    });
  });
}

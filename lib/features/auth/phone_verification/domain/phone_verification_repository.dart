import 'package:on_air/features/auth/domain/egypt_phone.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';

/// «أكّد رقمك» serves two flows: finishing a new registration and changing
/// the number of an active account (FR-013, FR-036).
enum PhoneVerificationPurpose { register, change }

/// The pending form values. Memory only (FR-015): no `toJson`, no storage —
/// the number is written server-side only inside `common_verify_otp`.
final class PhoneVerificationDraft {
  const PhoneVerificationDraft({
    required this.phone,
    required this.locale,
    this.fullName,
    this.acceptedTermsVersion,
  });

  final EgyptPhone phone;
  final String? fullName;
  final String? acceptedTermsVersion;
  final String locale;
}

/// Server timestamps only (R8, Constitution II): the UI derives countdowns
/// from them with the offset captured when the response arrived — it never
/// computes the ladder.
final class SendWindow {
  const SendWindow({
    required this.serverTime,
    required this.receivedAt,
    this.nextSendAt,
    this.blockedUntil,
  });

  final DateTime serverTime;

  /// The device time when the response carrying this window arrived; it
  /// freezes the server↔device offset so a skewed clock cannot cheat or
  /// over-wait (R8).
  final DateTime receivedAt;
  final DateTime? nextSendAt;

  /// Non-null means the server blocked this key until then; it overrides
  /// [nextSendAt].
  final DateTime? blockedUntil;

  /// How far the server clock was ahead of the device when the window
  /// arrived.
  Duration clockOffset() => serverTime.difference(receivedAt);

  /// Wait left before the next send: the server's own remaining time,
  /// decreased by the time elapsed since the response arrived. A skewed
  /// device clock only shifts the labels, never the wait. `Duration.zero`
  /// when sending is allowed now.
  Duration remainingUntilSend(DateTime deviceNow) {
    final next = nextSendAt;
    if (next == null) return Duration.zero;
    final serverNow = serverTime.add(deviceNow.difference(receivedAt));
    final remaining = next.difference(serverNow);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

enum DeliveryStatus { pending, sent, delivered, read, failed, unknown }

/// Only meaningful when the status is [DeliveryStatus.failed].
enum DeliveryFailure { notOnWhatsApp, other }

final class WhatsAppChallenge {
  const WhatsAppChallenge({
    required this.challengeId,
    required this.maskedPhone,
    required this.expiresAt,
    required this.window,
  });

  final String challengeId;

  /// The server-masked number, e.g. `+20 10•• ••• 678`.
  final String maskedPhone;
  final DateTime expiresAt;
  final SendWindow window;

  /// The same challenge under a fresh server window (the `RATE_LIMITED`
  /// refresh, T063).
  WhatsAppChallenge withWindow(SendWindow window) => WhatsAppChallenge(
    challengeId: challengeId,
    maskedPhone: maskedPhone,
    expiresAt: expiresAt,
    window: window,
  );
}

/// Every failure throws an `AppFailure` whose `ApiError.details` carries the
/// server payload (data-model §3).
abstract interface class PhoneVerificationRepository {
  Future<String> start(
    PhoneVerificationDraft draft,
    PhoneVerificationPurpose purpose,
  );
  Future<WhatsAppChallenge> send(String challengeId);
  Future<(DeliveryStatus, DeliveryFailure?, SendWindow)> status(
    String challengeId,
  );
  Future<GuestAccount> verify(String challengeId, String code);
}

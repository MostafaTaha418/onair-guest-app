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
/// from them with the device clock offset — it never computes the ladder.
final class SendWindow {
  const SendWindow({
    required this.serverTime,
    this.nextSendAt,
    this.blockedUntil,
  });

  final DateTime serverTime;
  final DateTime? nextSendAt;

  /// Non-null means the server blocked this key until then; it overrides
  /// [nextSendAt].
  final DateTime? blockedUntil;

  /// How far the server clock is ahead of [deviceNow].
  Duration clockOffset(DateTime deviceNow) => serverTime.difference(deviceNow);

  /// Wait left before the next send, using the server offset so a skewed
  /// device clock cannot cheat or over-wait. `Duration.zero` when sending is
  /// allowed now.
  Duration remainingUntilSend(DateTime deviceNow) {
    final next = nextSendAt;
    if (next == null) return Duration.zero;
    final serverNow = deviceNow.add(clockOffset(deviceNow));
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

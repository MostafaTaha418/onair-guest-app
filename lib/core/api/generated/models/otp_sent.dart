// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'otp_sent_channel.dart';

part 'otp_sent.freezed.dart';
part 'otp_sent.g.dart';

@Freezed()
abstract class OtpSent with _$OtpSent {
  const factory OtpSent({
    /// Where the code went (S005 A8).
    required OtpSentChannel channel,

    /// Masked destination: the email for `email`, the phone for `whatsapp` (e.g. "+20 10•• ••• 678").
    @JsonKey(name: 'masked_target') required String maskedTarget,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
    @JsonKey(name: 'server_time') required DateTime serverTime,
    @JsonKey(name: 'next_send_at') DateTime? nextSendAt,
    @JsonKey(name: 'blocked_until') DateTime? blockedUntil,

    /// Masked email, e.g. "a***@gmail.com"
    @JsonKey(name: 'sent_to_masked') String? sentToMasked,
    @JsonKey(name: 'retry_after_seconds') int? retryAfterSeconds,
  }) = _OtpSent;

  factory OtpSent.fromJson(Map<String, Object?> json) =>
      _$OtpSentFromJson(json);
}

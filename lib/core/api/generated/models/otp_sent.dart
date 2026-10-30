// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'otp_sent.freezed.dart';
part 'otp_sent.g.dart';

@Freezed()
abstract class OtpSent with _$OtpSent {
  const factory OtpSent({
    /// Masked email, e.g. "a***@gmail.com"
    @JsonKey(name: 'sent_to_masked') required String sentToMasked,
    @JsonKey(name: 'retry_after_seconds') required int retryAfterSeconds,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
  }) = _OtpSent;

  factory OtpSent.fromJson(Map<String, Object?> json) =>
      _$OtpSentFromJson(json);
}

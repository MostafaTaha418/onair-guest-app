// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_sent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OtpSent _$OtpSentFromJson(Map<String, dynamic> json) => _OtpSent(
  sentToMasked: json['sent_to_masked'] as String,
  retryAfterSeconds: (json['retry_after_seconds'] as num).toInt(),
  expiresAt: DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$OtpSentToJson(_OtpSent instance) => <String, dynamic>{
  'sent_to_masked': instance.sentToMasked,
  'retry_after_seconds': instance.retryAfterSeconds,
  'expires_at': instance.expiresAt.toIso8601String(),
};

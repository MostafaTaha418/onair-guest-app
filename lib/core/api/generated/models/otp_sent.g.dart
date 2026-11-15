// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_sent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OtpSent _$OtpSentFromJson(Map<String, dynamic> json) => _OtpSent(
  channel: OtpSentChannel.fromJson(json['channel'] as String),
  maskedTarget: json['masked_target'] as String,
  expiresAt: DateTime.parse(json['expires_at'] as String),
  serverTime: DateTime.parse(json['server_time'] as String),
  nextSendAt: json['next_send_at'] == null
      ? null
      : DateTime.parse(json['next_send_at'] as String),
  blockedUntil: json['blocked_until'] == null
      ? null
      : DateTime.parse(json['blocked_until'] as String),
  sentToMasked: json['sent_to_masked'] as String?,
  retryAfterSeconds: (json['retry_after_seconds'] as num?)?.toInt(),
);

Map<String, dynamic> _$OtpSentToJson(_OtpSent instance) => <String, dynamic>{
  'channel': _$OtpSentChannelEnumMap[instance.channel]!,
  'masked_target': instance.maskedTarget,
  'expires_at': instance.expiresAt.toIso8601String(),
  'server_time': instance.serverTime.toIso8601String(),
  'next_send_at': instance.nextSendAt?.toIso8601String(),
  'blocked_until': instance.blockedUntil?.toIso8601String(),
  'sent_to_masked': instance.sentToMasked,
  'retry_after_seconds': instance.retryAfterSeconds,
};

const _$OtpSentChannelEnumMap = {
  OtpSentChannel.email: 'email',
  OtpSentChannel.whatsapp: 'whatsapp',
  OtpSentChannel.$unknown: r'$unknown',
};

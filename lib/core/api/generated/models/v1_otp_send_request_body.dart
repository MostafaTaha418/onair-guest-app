// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'v1_otp_send_request_body.freezed.dart';
part 'v1_otp_send_request_body.g.dart';

@Freezed()
abstract class V1OtpSendRequestBody with _$V1OtpSendRequestBody {
  const factory V1OtpSendRequestBody({
    @JsonKey(name: 'challenge_id') required String challengeId,
  }) = _V1OtpSendRequestBody;

  factory V1OtpSendRequestBody.fromJson(Map<String, Object?> json) =>
      _$V1OtpSendRequestBodyFromJson(json);
}

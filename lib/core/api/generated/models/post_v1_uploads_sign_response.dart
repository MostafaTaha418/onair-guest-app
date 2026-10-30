// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_v1_uploads_sign_response.freezed.dart';
part 'post_v1_uploads_sign_response.g.dart';

@Freezed()
abstract class PostV1UploadsSignResponse with _$PostV1UploadsSignResponse {
  const factory PostV1UploadsSignResponse({
    @JsonKey(name: 'attachment_id') required String attachmentId,
    @JsonKey(name: 'upload_url') required String uploadUrl,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
  }) = _PostV1UploadsSignResponse;

  factory PostV1UploadsSignResponse.fromJson(Map<String, Object?> json) =>
      _$PostV1UploadsSignResponseFromJson(json);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_v1_uploads_sign_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PostV1UploadsSignResponse _$PostV1UploadsSignResponseFromJson(
  Map<String, dynamic> json,
) => _PostV1UploadsSignResponse(
  attachmentId: json['attachment_id'] as String,
  uploadUrl: json['upload_url'] as String,
  expiresAt: DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$PostV1UploadsSignResponseToJson(
  _PostV1UploadsSignResponse instance,
) => <String, dynamic>{
  'attachment_id': instance.attachmentId,
  'upload_url': instance.uploadUrl,
  'expires_at': instance.expiresAt.toIso8601String(),
};

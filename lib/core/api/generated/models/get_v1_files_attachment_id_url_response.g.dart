// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_v1_files_attachment_id_url_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GetV1FilesAttachmentIdUrlResponse _$GetV1FilesAttachmentIdUrlResponseFromJson(
  Map<String, dynamic> json,
) => _GetV1FilesAttachmentIdUrlResponse(
  url: json['url'] as String,
  expiresAt: DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$GetV1FilesAttachmentIdUrlResponseToJson(
  _GetV1FilesAttachmentIdUrlResponse instance,
) => <String, dynamic>{
  'url': instance.url,
  'expires_at': instance.expiresAt.toIso8601String(),
};

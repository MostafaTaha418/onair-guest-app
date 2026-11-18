// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_uploads_sign_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_V1UploadsSignRequestBody _$V1UploadsSignRequestBodyFromJson(
  Map<String, dynamic> json,
) => _V1UploadsSignRequestBody(
  entityType: EntityType.fromJson(json['entity_type'] as String),
  entityId: json['entity_id'] as String,
  mimeType: MimeType.fromJson(json['mime_type'] as String),
  sizeBytes: (json['size_bytes'] as num).toInt(),
);

Map<String, dynamic> _$V1UploadsSignRequestBodyToJson(
  _V1UploadsSignRequestBody instance,
) => <String, dynamic>{
  'entity_type': _$EntityTypeEnumMap[instance.entityType]!,
  'entity_id': instance.entityId,
  'mime_type': _$MimeTypeEnumMap[instance.mimeType]!,
  'size_bytes': instance.sizeBytes,
};

const _$EntityTypeEnumMap = {
  EntityType.supportCase: 'support_case',
  EntityType.caseMessage: 'case_message',
  EntityType.damageClaim: 'damage_claim',
  EntityType.$unknown: r'$unknown',
};

const _$MimeTypeEnumMap = {
  MimeType.undefined0: 'image/jpeg',
  MimeType.undefined1: 'image/png',
  MimeType.undefined2: 'image/webp',
  MimeType.undefined3: 'application/pdf',
  MimeType.$unknown: r'$unknown',
};

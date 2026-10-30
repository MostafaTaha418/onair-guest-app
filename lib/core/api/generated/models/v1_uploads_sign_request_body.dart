// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'entity_type.dart';
import 'mime_type.dart';

part 'v1_uploads_sign_request_body.freezed.dart';
part 'v1_uploads_sign_request_body.g.dart';

@Freezed()
abstract class V1UploadsSignRequestBody with _$V1UploadsSignRequestBody {
  const factory V1UploadsSignRequestBody({
    @JsonKey(name: 'entity_type') required EntityType entityType,
    @JsonKey(name: 'entity_id') required String entityId,
    @JsonKey(name: 'mime_type') required MimeType mimeType,
    @JsonKey(name: 'size_bytes') required int sizeBytes,
  }) = _V1UploadsSignRequestBody;

  factory V1UploadsSignRequestBody.fromJson(Map<String, Object?> json) =>
      _$V1UploadsSignRequestBodyFromJson(json);
}

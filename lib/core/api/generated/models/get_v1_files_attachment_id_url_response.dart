// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'get_v1_files_attachment_id_url_response.freezed.dart';
part 'get_v1_files_attachment_id_url_response.g.dart';

@Freezed()
abstract class GetV1FilesAttachmentIdUrlResponse
    with _$GetV1FilesAttachmentIdUrlResponse {
  const factory GetV1FilesAttachmentIdUrlResponse({
    required String url,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
  }) = _GetV1FilesAttachmentIdUrlResponse;

  factory GetV1FilesAttachmentIdUrlResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetV1FilesAttachmentIdUrlResponseFromJson(json);
}

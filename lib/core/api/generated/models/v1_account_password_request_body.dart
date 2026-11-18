// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'v1_account_password_request_body.freezed.dart';
part 'v1_account_password_request_body.g.dart';

@Freezed()
abstract class V1AccountPasswordRequestBody
    with _$V1AccountPasswordRequestBody {
  const factory V1AccountPasswordRequestBody({
    @JsonKey(name: 'current_password') required String currentPassword,
    @JsonKey(name: 'new_password') required String newPassword,
  }) = _V1AccountPasswordRequestBody;

  factory V1AccountPasswordRequestBody.fromJson(Map<String, Object?> json) =>
      _$V1AccountPasswordRequestBodyFromJson(json);
}

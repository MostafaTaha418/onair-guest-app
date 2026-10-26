// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'error_code.dart';
import 'details.dart';

part 'error.freezed.dart';
part 'error.g.dart';

@Freezed()
abstract class Error with _$Error {
  const factory Error({
    required ErrorCode code,
    @JsonKey(name: 'message_key') required String messageKey,
    @JsonKey(name: 'request_id') required String requestId,
    Details? details,
  }) = _Error;

  factory Error.fromJson(Map<String, Object?> json) => _$ErrorFromJson(json);
}

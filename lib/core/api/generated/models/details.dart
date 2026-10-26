// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'details.freezed.dart';
part 'details.g.dart';

@Freezed()
abstract class Details with _$Details {
  const factory Details({
    @JsonKey(name: 'retry_after_seconds') int? retryAfterSeconds,
  }) = _Details;

  factory Details.fromJson(Map<String, Object?> json) =>
      _$DetailsFromJson(json);
}

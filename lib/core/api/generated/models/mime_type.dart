// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum MimeType {
  /// Incorrect name has been replaced. Original name: `image/jpeg`.
  @JsonValue('image/jpeg')
  undefined0('image/jpeg'),

  /// Incorrect name has been replaced. Original name: `image/png`.
  @JsonValue('image/png')
  undefined1('image/png'),

  /// Incorrect name has been replaced. Original name: `image/webp`.
  @JsonValue('image/webp')
  undefined2('image/webp'),

  /// Incorrect name has been replaced. Original name: `application/pdf`.
  @JsonValue('application/pdf')
  undefined3('application/pdf'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const MimeType(this.json);

  factory MimeType.fromJson(String json) => values.firstWhere(
    (e) => e.json == json,
    orElse: () => $unknown,
  );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<MimeType> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}

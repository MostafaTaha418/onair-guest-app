// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum EntityType {
  @JsonValue('support_case')
  supportCase('support_case'),
  @JsonValue('case_message')
  caseMessage('case_message'),
  @JsonValue('damage_claim')
  damageClaim('damage_claim'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const EntityType(this.json);

  factory EntityType.fromJson(String json) => values.firstWhere(
    (e) => e.json == json,
    orElse: () => $unknown,
  );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<EntityType> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}

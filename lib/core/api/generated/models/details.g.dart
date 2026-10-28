// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Details _$DetailsFromJson(Map<String, dynamic> json) =>
    _Details(retryAfterSeconds: (json['retry_after_seconds'] as num?)?.toInt());

Map<String, dynamic> _$DetailsToJson(_Details instance) => <String, dynamic>{
  'retry_after_seconds': instance.retryAfterSeconds,
};

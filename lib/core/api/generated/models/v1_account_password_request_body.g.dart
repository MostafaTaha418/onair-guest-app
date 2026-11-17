// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_account_password_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_V1AccountPasswordRequestBody _$V1AccountPasswordRequestBodyFromJson(
  Map<String, dynamic> json,
) => _V1AccountPasswordRequestBody(
  currentPassword: json['current_password'] as String,
  newPassword: json['new_password'] as String,
);

Map<String, dynamic> _$V1AccountPasswordRequestBodyToJson(
  _V1AccountPasswordRequestBody instance,
) => <String, dynamic>{
  'current_password': instance.currentPassword,
  'new_password': instance.newPassword,
};

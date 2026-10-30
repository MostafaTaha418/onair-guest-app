// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_v1_uploads_sign_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PostV1UploadsSignResponse {

@JsonKey(name: 'attachment_id') String get attachmentId;@JsonKey(name: 'upload_url') String get uploadUrl;@JsonKey(name: 'expires_at') DateTime get expiresAt;
/// Create a copy of PostV1UploadsSignResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostV1UploadsSignResponseCopyWith<PostV1UploadsSignResponse> get copyWith => _$PostV1UploadsSignResponseCopyWithImpl<PostV1UploadsSignResponse>(this as PostV1UploadsSignResponse, _$identity);

  /// Serializes this PostV1UploadsSignResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostV1UploadsSignResponse&&(identical(other.attachmentId, attachmentId) || other.attachmentId == attachmentId)&&(identical(other.uploadUrl, uploadUrl) || other.uploadUrl == uploadUrl)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attachmentId,uploadUrl,expiresAt);

@override
String toString() {
  return 'PostV1UploadsSignResponse(attachmentId: $attachmentId, uploadUrl: $uploadUrl, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $PostV1UploadsSignResponseCopyWith<$Res>  {
  factory $PostV1UploadsSignResponseCopyWith(PostV1UploadsSignResponse value, $Res Function(PostV1UploadsSignResponse) _then) = _$PostV1UploadsSignResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'attachment_id') String attachmentId,@JsonKey(name: 'upload_url') String uploadUrl,@JsonKey(name: 'expires_at') DateTime expiresAt
});




}
/// @nodoc
class _$PostV1UploadsSignResponseCopyWithImpl<$Res>
    implements $PostV1UploadsSignResponseCopyWith<$Res> {
  _$PostV1UploadsSignResponseCopyWithImpl(this._self, this._then);

  final PostV1UploadsSignResponse _self;
  final $Res Function(PostV1UploadsSignResponse) _then;

/// Create a copy of PostV1UploadsSignResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? attachmentId = null,Object? uploadUrl = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
attachmentId: null == attachmentId ? _self.attachmentId : attachmentId // ignore: cast_nullable_to_non_nullable
as String,uploadUrl: null == uploadUrl ? _self.uploadUrl : uploadUrl // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PostV1UploadsSignResponse].
extension PostV1UploadsSignResponsePatterns on PostV1UploadsSignResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostV1UploadsSignResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostV1UploadsSignResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostV1UploadsSignResponse value)  $default,){
final _that = this;
switch (_that) {
case _PostV1UploadsSignResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostV1UploadsSignResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PostV1UploadsSignResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'attachment_id')  String attachmentId, @JsonKey(name: 'upload_url')  String uploadUrl, @JsonKey(name: 'expires_at')  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostV1UploadsSignResponse() when $default != null:
return $default(_that.attachmentId,_that.uploadUrl,_that.expiresAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'attachment_id')  String attachmentId, @JsonKey(name: 'upload_url')  String uploadUrl, @JsonKey(name: 'expires_at')  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _PostV1UploadsSignResponse():
return $default(_that.attachmentId,_that.uploadUrl,_that.expiresAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'attachment_id')  String attachmentId, @JsonKey(name: 'upload_url')  String uploadUrl, @JsonKey(name: 'expires_at')  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _PostV1UploadsSignResponse() when $default != null:
return $default(_that.attachmentId,_that.uploadUrl,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PostV1UploadsSignResponse implements PostV1UploadsSignResponse {
  const _PostV1UploadsSignResponse({@JsonKey(name: 'attachment_id') required this.attachmentId, @JsonKey(name: 'upload_url') required this.uploadUrl, @JsonKey(name: 'expires_at') required this.expiresAt});
  factory _PostV1UploadsSignResponse.fromJson(Map<String, dynamic> json) => _$PostV1UploadsSignResponseFromJson(json);

@override@JsonKey(name: 'attachment_id') final  String attachmentId;
@override@JsonKey(name: 'upload_url') final  String uploadUrl;
@override@JsonKey(name: 'expires_at') final  DateTime expiresAt;

/// Create a copy of PostV1UploadsSignResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostV1UploadsSignResponseCopyWith<_PostV1UploadsSignResponse> get copyWith => __$PostV1UploadsSignResponseCopyWithImpl<_PostV1UploadsSignResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PostV1UploadsSignResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostV1UploadsSignResponse&&(identical(other.attachmentId, attachmentId) || other.attachmentId == attachmentId)&&(identical(other.uploadUrl, uploadUrl) || other.uploadUrl == uploadUrl)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attachmentId,uploadUrl,expiresAt);

@override
String toString() {
  return 'PostV1UploadsSignResponse(attachmentId: $attachmentId, uploadUrl: $uploadUrl, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$PostV1UploadsSignResponseCopyWith<$Res> implements $PostV1UploadsSignResponseCopyWith<$Res> {
  factory _$PostV1UploadsSignResponseCopyWith(_PostV1UploadsSignResponse value, $Res Function(_PostV1UploadsSignResponse) _then) = __$PostV1UploadsSignResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'attachment_id') String attachmentId,@JsonKey(name: 'upload_url') String uploadUrl,@JsonKey(name: 'expires_at') DateTime expiresAt
});




}
/// @nodoc
class __$PostV1UploadsSignResponseCopyWithImpl<$Res>
    implements _$PostV1UploadsSignResponseCopyWith<$Res> {
  __$PostV1UploadsSignResponseCopyWithImpl(this._self, this._then);

  final _PostV1UploadsSignResponse _self;
  final $Res Function(_PostV1UploadsSignResponse) _then;

/// Create a copy of PostV1UploadsSignResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? attachmentId = null,Object? uploadUrl = null,Object? expiresAt = null,}) {
  return _then(_PostV1UploadsSignResponse(
attachmentId: null == attachmentId ? _self.attachmentId : attachmentId // ignore: cast_nullable_to_non_nullable
as String,uploadUrl: null == uploadUrl ? _self.uploadUrl : uploadUrl // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

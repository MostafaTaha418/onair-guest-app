// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'get_v1_files_attachment_id_url_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GetV1FilesAttachmentIdUrlResponse {

 String get url;@JsonKey(name: 'expires_at') DateTime get expiresAt;
/// Create a copy of GetV1FilesAttachmentIdUrlResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GetV1FilesAttachmentIdUrlResponseCopyWith<GetV1FilesAttachmentIdUrlResponse> get copyWith => _$GetV1FilesAttachmentIdUrlResponseCopyWithImpl<GetV1FilesAttachmentIdUrlResponse>(this as GetV1FilesAttachmentIdUrlResponse, _$identity);

  /// Serializes this GetV1FilesAttachmentIdUrlResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GetV1FilesAttachmentIdUrlResponse&&(identical(other.url, url) || other.url == url)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,expiresAt);

@override
String toString() {
  return 'GetV1FilesAttachmentIdUrlResponse(url: $url, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $GetV1FilesAttachmentIdUrlResponseCopyWith<$Res>  {
  factory $GetV1FilesAttachmentIdUrlResponseCopyWith(GetV1FilesAttachmentIdUrlResponse value, $Res Function(GetV1FilesAttachmentIdUrlResponse) _then) = _$GetV1FilesAttachmentIdUrlResponseCopyWithImpl;
@useResult
$Res call({
 String url,@JsonKey(name: 'expires_at') DateTime expiresAt
});




}
/// @nodoc
class _$GetV1FilesAttachmentIdUrlResponseCopyWithImpl<$Res>
    implements $GetV1FilesAttachmentIdUrlResponseCopyWith<$Res> {
  _$GetV1FilesAttachmentIdUrlResponseCopyWithImpl(this._self, this._then);

  final GetV1FilesAttachmentIdUrlResponse _self;
  final $Res Function(GetV1FilesAttachmentIdUrlResponse) _then;

/// Create a copy of GetV1FilesAttachmentIdUrlResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [GetV1FilesAttachmentIdUrlResponse].
extension GetV1FilesAttachmentIdUrlResponsePatterns on GetV1FilesAttachmentIdUrlResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GetV1FilesAttachmentIdUrlResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GetV1FilesAttachmentIdUrlResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GetV1FilesAttachmentIdUrlResponse value)  $default,){
final _that = this;
switch (_that) {
case _GetV1FilesAttachmentIdUrlResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GetV1FilesAttachmentIdUrlResponse value)?  $default,){
final _that = this;
switch (_that) {
case _GetV1FilesAttachmentIdUrlResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url, @JsonKey(name: 'expires_at')  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GetV1FilesAttachmentIdUrlResponse() when $default != null:
return $default(_that.url,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url, @JsonKey(name: 'expires_at')  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _GetV1FilesAttachmentIdUrlResponse():
return $default(_that.url,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url, @JsonKey(name: 'expires_at')  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _GetV1FilesAttachmentIdUrlResponse() when $default != null:
return $default(_that.url,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GetV1FilesAttachmentIdUrlResponse implements GetV1FilesAttachmentIdUrlResponse {
  const _GetV1FilesAttachmentIdUrlResponse({required this.url, @JsonKey(name: 'expires_at') required this.expiresAt});
  factory _GetV1FilesAttachmentIdUrlResponse.fromJson(Map<String, dynamic> json) => _$GetV1FilesAttachmentIdUrlResponseFromJson(json);

@override final  String url;
@override@JsonKey(name: 'expires_at') final  DateTime expiresAt;

/// Create a copy of GetV1FilesAttachmentIdUrlResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GetV1FilesAttachmentIdUrlResponseCopyWith<_GetV1FilesAttachmentIdUrlResponse> get copyWith => __$GetV1FilesAttachmentIdUrlResponseCopyWithImpl<_GetV1FilesAttachmentIdUrlResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GetV1FilesAttachmentIdUrlResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GetV1FilesAttachmentIdUrlResponse&&(identical(other.url, url) || other.url == url)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,expiresAt);

@override
String toString() {
  return 'GetV1FilesAttachmentIdUrlResponse(url: $url, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$GetV1FilesAttachmentIdUrlResponseCopyWith<$Res> implements $GetV1FilesAttachmentIdUrlResponseCopyWith<$Res> {
  factory _$GetV1FilesAttachmentIdUrlResponseCopyWith(_GetV1FilesAttachmentIdUrlResponse value, $Res Function(_GetV1FilesAttachmentIdUrlResponse) _then) = __$GetV1FilesAttachmentIdUrlResponseCopyWithImpl;
@override @useResult
$Res call({
 String url,@JsonKey(name: 'expires_at') DateTime expiresAt
});




}
/// @nodoc
class __$GetV1FilesAttachmentIdUrlResponseCopyWithImpl<$Res>
    implements _$GetV1FilesAttachmentIdUrlResponseCopyWith<$Res> {
  __$GetV1FilesAttachmentIdUrlResponseCopyWithImpl(this._self, this._then);

  final _GetV1FilesAttachmentIdUrlResponse _self;
  final $Res Function(_GetV1FilesAttachmentIdUrlResponse) _then;

/// Create a copy of GetV1FilesAttachmentIdUrlResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? expiresAt = null,}) {
  return _then(_GetV1FilesAttachmentIdUrlResponse(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

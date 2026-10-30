// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'v1_uploads_sign_request_body.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$V1UploadsSignRequestBody {

@JsonKey(name: 'entity_type') EntityType get entityType;@JsonKey(name: 'entity_id') String get entityId;@JsonKey(name: 'mime_type') MimeType get mimeType;@JsonKey(name: 'size_bytes') int get sizeBytes;
/// Create a copy of V1UploadsSignRequestBody
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$V1UploadsSignRequestBodyCopyWith<V1UploadsSignRequestBody> get copyWith => _$V1UploadsSignRequestBodyCopyWithImpl<V1UploadsSignRequestBody>(this as V1UploadsSignRequestBody, _$identity);

  /// Serializes this V1UploadsSignRequestBody to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is V1UploadsSignRequestBody&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,entityType,entityId,mimeType,sizeBytes);

@override
String toString() {
  return 'V1UploadsSignRequestBody(entityType: $entityType, entityId: $entityId, mimeType: $mimeType, sizeBytes: $sizeBytes)';
}


}

/// @nodoc
abstract mixin class $V1UploadsSignRequestBodyCopyWith<$Res>  {
  factory $V1UploadsSignRequestBodyCopyWith(V1UploadsSignRequestBody value, $Res Function(V1UploadsSignRequestBody) _then) = _$V1UploadsSignRequestBodyCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'entity_type') EntityType entityType,@JsonKey(name: 'entity_id') String entityId,@JsonKey(name: 'mime_type') MimeType mimeType,@JsonKey(name: 'size_bytes') int sizeBytes
});




}
/// @nodoc
class _$V1UploadsSignRequestBodyCopyWithImpl<$Res>
    implements $V1UploadsSignRequestBodyCopyWith<$Res> {
  _$V1UploadsSignRequestBodyCopyWithImpl(this._self, this._then);

  final V1UploadsSignRequestBody _self;
  final $Res Function(V1UploadsSignRequestBody) _then;

/// Create a copy of V1UploadsSignRequestBody
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entityType = null,Object? entityId = null,Object? mimeType = null,Object? sizeBytes = null,}) {
  return _then(_self.copyWith(
entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as MimeType,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [V1UploadsSignRequestBody].
extension V1UploadsSignRequestBodyPatterns on V1UploadsSignRequestBody {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _V1UploadsSignRequestBody value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _V1UploadsSignRequestBody() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _V1UploadsSignRequestBody value)  $default,){
final _that = this;
switch (_that) {
case _V1UploadsSignRequestBody():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _V1UploadsSignRequestBody value)?  $default,){
final _that = this;
switch (_that) {
case _V1UploadsSignRequestBody() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'entity_type')  EntityType entityType, @JsonKey(name: 'entity_id')  String entityId, @JsonKey(name: 'mime_type')  MimeType mimeType, @JsonKey(name: 'size_bytes')  int sizeBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _V1UploadsSignRequestBody() when $default != null:
return $default(_that.entityType,_that.entityId,_that.mimeType,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'entity_type')  EntityType entityType, @JsonKey(name: 'entity_id')  String entityId, @JsonKey(name: 'mime_type')  MimeType mimeType, @JsonKey(name: 'size_bytes')  int sizeBytes)  $default,) {final _that = this;
switch (_that) {
case _V1UploadsSignRequestBody():
return $default(_that.entityType,_that.entityId,_that.mimeType,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'entity_type')  EntityType entityType, @JsonKey(name: 'entity_id')  String entityId, @JsonKey(name: 'mime_type')  MimeType mimeType, @JsonKey(name: 'size_bytes')  int sizeBytes)?  $default,) {final _that = this;
switch (_that) {
case _V1UploadsSignRequestBody() when $default != null:
return $default(_that.entityType,_that.entityId,_that.mimeType,_that.sizeBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _V1UploadsSignRequestBody implements V1UploadsSignRequestBody {
  const _V1UploadsSignRequestBody({@JsonKey(name: 'entity_type') required this.entityType, @JsonKey(name: 'entity_id') required this.entityId, @JsonKey(name: 'mime_type') required this.mimeType, @JsonKey(name: 'size_bytes') required this.sizeBytes});
  factory _V1UploadsSignRequestBody.fromJson(Map<String, dynamic> json) => _$V1UploadsSignRequestBodyFromJson(json);

@override@JsonKey(name: 'entity_type') final  EntityType entityType;
@override@JsonKey(name: 'entity_id') final  String entityId;
@override@JsonKey(name: 'mime_type') final  MimeType mimeType;
@override@JsonKey(name: 'size_bytes') final  int sizeBytes;

/// Create a copy of V1UploadsSignRequestBody
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$V1UploadsSignRequestBodyCopyWith<_V1UploadsSignRequestBody> get copyWith => __$V1UploadsSignRequestBodyCopyWithImpl<_V1UploadsSignRequestBody>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$V1UploadsSignRequestBodyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _V1UploadsSignRequestBody&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,entityType,entityId,mimeType,sizeBytes);

@override
String toString() {
  return 'V1UploadsSignRequestBody(entityType: $entityType, entityId: $entityId, mimeType: $mimeType, sizeBytes: $sizeBytes)';
}


}

/// @nodoc
abstract mixin class _$V1UploadsSignRequestBodyCopyWith<$Res> implements $V1UploadsSignRequestBodyCopyWith<$Res> {
  factory _$V1UploadsSignRequestBodyCopyWith(_V1UploadsSignRequestBody value, $Res Function(_V1UploadsSignRequestBody) _then) = __$V1UploadsSignRequestBodyCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'entity_type') EntityType entityType,@JsonKey(name: 'entity_id') String entityId,@JsonKey(name: 'mime_type') MimeType mimeType,@JsonKey(name: 'size_bytes') int sizeBytes
});




}
/// @nodoc
class __$V1UploadsSignRequestBodyCopyWithImpl<$Res>
    implements _$V1UploadsSignRequestBodyCopyWith<$Res> {
  __$V1UploadsSignRequestBodyCopyWithImpl(this._self, this._then);

  final _V1UploadsSignRequestBody _self;
  final $Res Function(_V1UploadsSignRequestBody) _then;

/// Create a copy of V1UploadsSignRequestBody
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entityType = null,Object? entityId = null,Object? mimeType = null,Object? sizeBytes = null,}) {
  return _then(_V1UploadsSignRequestBody(
entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as MimeType,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

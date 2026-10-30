// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'v1_otp_send_request_body.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$V1OtpSendRequestBody {

@JsonKey(name: 'challenge_id') String get challengeId;
/// Create a copy of V1OtpSendRequestBody
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$V1OtpSendRequestBodyCopyWith<V1OtpSendRequestBody> get copyWith => _$V1OtpSendRequestBodyCopyWithImpl<V1OtpSendRequestBody>(this as V1OtpSendRequestBody, _$identity);

  /// Serializes this V1OtpSendRequestBody to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is V1OtpSendRequestBody&&(identical(other.challengeId, challengeId) || other.challengeId == challengeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,challengeId);

@override
String toString() {
  return 'V1OtpSendRequestBody(challengeId: $challengeId)';
}


}

/// @nodoc
abstract mixin class $V1OtpSendRequestBodyCopyWith<$Res>  {
  factory $V1OtpSendRequestBodyCopyWith(V1OtpSendRequestBody value, $Res Function(V1OtpSendRequestBody) _then) = _$V1OtpSendRequestBodyCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'challenge_id') String challengeId
});




}
/// @nodoc
class _$V1OtpSendRequestBodyCopyWithImpl<$Res>
    implements $V1OtpSendRequestBodyCopyWith<$Res> {
  _$V1OtpSendRequestBodyCopyWithImpl(this._self, this._then);

  final V1OtpSendRequestBody _self;
  final $Res Function(V1OtpSendRequestBody) _then;

/// Create a copy of V1OtpSendRequestBody
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? challengeId = null,}) {
  return _then(_self.copyWith(
challengeId: null == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [V1OtpSendRequestBody].
extension V1OtpSendRequestBodyPatterns on V1OtpSendRequestBody {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _V1OtpSendRequestBody value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _V1OtpSendRequestBody() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _V1OtpSendRequestBody value)  $default,){
final _that = this;
switch (_that) {
case _V1OtpSendRequestBody():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _V1OtpSendRequestBody value)?  $default,){
final _that = this;
switch (_that) {
case _V1OtpSendRequestBody() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'challenge_id')  String challengeId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _V1OtpSendRequestBody() when $default != null:
return $default(_that.challengeId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'challenge_id')  String challengeId)  $default,) {final _that = this;
switch (_that) {
case _V1OtpSendRequestBody():
return $default(_that.challengeId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'challenge_id')  String challengeId)?  $default,) {final _that = this;
switch (_that) {
case _V1OtpSendRequestBody() when $default != null:
return $default(_that.challengeId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _V1OtpSendRequestBody implements V1OtpSendRequestBody {
  const _V1OtpSendRequestBody({@JsonKey(name: 'challenge_id') required this.challengeId});
  factory _V1OtpSendRequestBody.fromJson(Map<String, dynamic> json) => _$V1OtpSendRequestBodyFromJson(json);

@override@JsonKey(name: 'challenge_id') final  String challengeId;

/// Create a copy of V1OtpSendRequestBody
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$V1OtpSendRequestBodyCopyWith<_V1OtpSendRequestBody> get copyWith => __$V1OtpSendRequestBodyCopyWithImpl<_V1OtpSendRequestBody>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$V1OtpSendRequestBodyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _V1OtpSendRequestBody&&(identical(other.challengeId, challengeId) || other.challengeId == challengeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,challengeId);

@override
String toString() {
  return 'V1OtpSendRequestBody(challengeId: $challengeId)';
}


}

/// @nodoc
abstract mixin class _$V1OtpSendRequestBodyCopyWith<$Res> implements $V1OtpSendRequestBodyCopyWith<$Res> {
  factory _$V1OtpSendRequestBodyCopyWith(_V1OtpSendRequestBody value, $Res Function(_V1OtpSendRequestBody) _then) = __$V1OtpSendRequestBodyCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'challenge_id') String challengeId
});




}
/// @nodoc
class __$V1OtpSendRequestBodyCopyWithImpl<$Res>
    implements _$V1OtpSendRequestBodyCopyWith<$Res> {
  __$V1OtpSendRequestBodyCopyWithImpl(this._self, this._then);

  final _V1OtpSendRequestBody _self;
  final $Res Function(_V1OtpSendRequestBody) _then;

/// Create a copy of V1OtpSendRequestBody
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? challengeId = null,}) {
  return _then(_V1OtpSendRequestBody(
challengeId: null == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

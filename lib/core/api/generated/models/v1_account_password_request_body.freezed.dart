// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'v1_account_password_request_body.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$V1AccountPasswordRequestBody {

@JsonKey(name: 'current_password') String get currentPassword;@JsonKey(name: 'new_password') String get newPassword;
/// Create a copy of V1AccountPasswordRequestBody
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$V1AccountPasswordRequestBodyCopyWith<V1AccountPasswordRequestBody> get copyWith => _$V1AccountPasswordRequestBodyCopyWithImpl<V1AccountPasswordRequestBody>(this as V1AccountPasswordRequestBody, _$identity);

  /// Serializes this V1AccountPasswordRequestBody to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is V1AccountPasswordRequestBody&&(identical(other.currentPassword, currentPassword) || other.currentPassword == currentPassword)&&(identical(other.newPassword, newPassword) || other.newPassword == newPassword));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currentPassword,newPassword);

@override
String toString() {
  return 'V1AccountPasswordRequestBody(currentPassword: $currentPassword, newPassword: $newPassword)';
}


}

/// @nodoc
abstract mixin class $V1AccountPasswordRequestBodyCopyWith<$Res>  {
  factory $V1AccountPasswordRequestBodyCopyWith(V1AccountPasswordRequestBody value, $Res Function(V1AccountPasswordRequestBody) _then) = _$V1AccountPasswordRequestBodyCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'current_password') String currentPassword,@JsonKey(name: 'new_password') String newPassword
});




}
/// @nodoc
class _$V1AccountPasswordRequestBodyCopyWithImpl<$Res>
    implements $V1AccountPasswordRequestBodyCopyWith<$Res> {
  _$V1AccountPasswordRequestBodyCopyWithImpl(this._self, this._then);

  final V1AccountPasswordRequestBody _self;
  final $Res Function(V1AccountPasswordRequestBody) _then;

/// Create a copy of V1AccountPasswordRequestBody
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentPassword = null,Object? newPassword = null,}) {
  return _then(_self.copyWith(
currentPassword: null == currentPassword ? _self.currentPassword : currentPassword // ignore: cast_nullable_to_non_nullable
as String,newPassword: null == newPassword ? _self.newPassword : newPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [V1AccountPasswordRequestBody].
extension V1AccountPasswordRequestBodyPatterns on V1AccountPasswordRequestBody {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _V1AccountPasswordRequestBody value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _V1AccountPasswordRequestBody() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _V1AccountPasswordRequestBody value)  $default,){
final _that = this;
switch (_that) {
case _V1AccountPasswordRequestBody():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _V1AccountPasswordRequestBody value)?  $default,){
final _that = this;
switch (_that) {
case _V1AccountPasswordRequestBody() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'current_password')  String currentPassword, @JsonKey(name: 'new_password')  String newPassword)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _V1AccountPasswordRequestBody() when $default != null:
return $default(_that.currentPassword,_that.newPassword);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'current_password')  String currentPassword, @JsonKey(name: 'new_password')  String newPassword)  $default,) {final _that = this;
switch (_that) {
case _V1AccountPasswordRequestBody():
return $default(_that.currentPassword,_that.newPassword);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'current_password')  String currentPassword, @JsonKey(name: 'new_password')  String newPassword)?  $default,) {final _that = this;
switch (_that) {
case _V1AccountPasswordRequestBody() when $default != null:
return $default(_that.currentPassword,_that.newPassword);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _V1AccountPasswordRequestBody implements V1AccountPasswordRequestBody {
  const _V1AccountPasswordRequestBody({@JsonKey(name: 'current_password') required this.currentPassword, @JsonKey(name: 'new_password') required this.newPassword});
  factory _V1AccountPasswordRequestBody.fromJson(Map<String, dynamic> json) => _$V1AccountPasswordRequestBodyFromJson(json);

@override@JsonKey(name: 'current_password') final  String currentPassword;
@override@JsonKey(name: 'new_password') final  String newPassword;

/// Create a copy of V1AccountPasswordRequestBody
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$V1AccountPasswordRequestBodyCopyWith<_V1AccountPasswordRequestBody> get copyWith => __$V1AccountPasswordRequestBodyCopyWithImpl<_V1AccountPasswordRequestBody>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$V1AccountPasswordRequestBodyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _V1AccountPasswordRequestBody&&(identical(other.currentPassword, currentPassword) || other.currentPassword == currentPassword)&&(identical(other.newPassword, newPassword) || other.newPassword == newPassword));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currentPassword,newPassword);

@override
String toString() {
  return 'V1AccountPasswordRequestBody(currentPassword: $currentPassword, newPassword: $newPassword)';
}


}

/// @nodoc
abstract mixin class _$V1AccountPasswordRequestBodyCopyWith<$Res> implements $V1AccountPasswordRequestBodyCopyWith<$Res> {
  factory _$V1AccountPasswordRequestBodyCopyWith(_V1AccountPasswordRequestBody value, $Res Function(_V1AccountPasswordRequestBody) _then) = __$V1AccountPasswordRequestBodyCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'current_password') String currentPassword,@JsonKey(name: 'new_password') String newPassword
});




}
/// @nodoc
class __$V1AccountPasswordRequestBodyCopyWithImpl<$Res>
    implements _$V1AccountPasswordRequestBodyCopyWith<$Res> {
  __$V1AccountPasswordRequestBodyCopyWithImpl(this._self, this._then);

  final _V1AccountPasswordRequestBody _self;
  final $Res Function(_V1AccountPasswordRequestBody) _then;

/// Create a copy of V1AccountPasswordRequestBody
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentPassword = null,Object? newPassword = null,}) {
  return _then(_V1AccountPasswordRequestBody(
currentPassword: null == currentPassword ? _self.currentPassword : currentPassword // ignore: cast_nullable_to_non_nullable
as String,newPassword: null == newPassword ? _self.newPassword : newPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

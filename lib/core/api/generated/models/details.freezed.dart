// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'details.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Details {

@JsonKey(name: 'retry_after_seconds') int? get retryAfterSeconds;
/// Create a copy of Details
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DetailsCopyWith<Details> get copyWith => _$DetailsCopyWithImpl<Details>(this as Details, _$identity);

  /// Serializes this Details to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Details&&(identical(other.retryAfterSeconds, retryAfterSeconds) || other.retryAfterSeconds == retryAfterSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,retryAfterSeconds);

@override
String toString() {
  return 'Details(retryAfterSeconds: $retryAfterSeconds)';
}


}

/// @nodoc
abstract mixin class $DetailsCopyWith<$Res>  {
  factory $DetailsCopyWith(Details value, $Res Function(Details) _then) = _$DetailsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'retry_after_seconds') int? retryAfterSeconds
});




}
/// @nodoc
class _$DetailsCopyWithImpl<$Res>
    implements $DetailsCopyWith<$Res> {
  _$DetailsCopyWithImpl(this._self, this._then);

  final Details _self;
  final $Res Function(Details) _then;

/// Create a copy of Details
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? retryAfterSeconds = freezed,}) {
  return _then(_self.copyWith(
retryAfterSeconds: freezed == retryAfterSeconds ? _self.retryAfterSeconds : retryAfterSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Details].
extension DetailsPatterns on Details {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Details value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Details() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Details value)  $default,){
final _that = this;
switch (_that) {
case _Details():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Details value)?  $default,){
final _that = this;
switch (_that) {
case _Details() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'retry_after_seconds')  int? retryAfterSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Details() when $default != null:
return $default(_that.retryAfterSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'retry_after_seconds')  int? retryAfterSeconds)  $default,) {final _that = this;
switch (_that) {
case _Details():
return $default(_that.retryAfterSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'retry_after_seconds')  int? retryAfterSeconds)?  $default,) {final _that = this;
switch (_that) {
case _Details() when $default != null:
return $default(_that.retryAfterSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Details implements Details {
  const _Details({@JsonKey(name: 'retry_after_seconds') this.retryAfterSeconds});
  factory _Details.fromJson(Map<String, dynamic> json) => _$DetailsFromJson(json);

@override@JsonKey(name: 'retry_after_seconds') final  int? retryAfterSeconds;

/// Create a copy of Details
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DetailsCopyWith<_Details> get copyWith => __$DetailsCopyWithImpl<_Details>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Details&&(identical(other.retryAfterSeconds, retryAfterSeconds) || other.retryAfterSeconds == retryAfterSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,retryAfterSeconds);

@override
String toString() {
  return 'Details(retryAfterSeconds: $retryAfterSeconds)';
}


}

/// @nodoc
abstract mixin class _$DetailsCopyWith<$Res> implements $DetailsCopyWith<$Res> {
  factory _$DetailsCopyWith(_Details value, $Res Function(_Details) _then) = __$DetailsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'retry_after_seconds') int? retryAfterSeconds
});




}
/// @nodoc
class __$DetailsCopyWithImpl<$Res>
    implements _$DetailsCopyWith<$Res> {
  __$DetailsCopyWithImpl(this._self, this._then);

  final _Details _self;
  final $Res Function(_Details) _then;

/// Create a copy of Details
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? retryAfterSeconds = freezed,}) {
  return _then(_Details(
retryAfterSeconds: freezed == retryAfterSeconds ? _self.retryAfterSeconds : retryAfterSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

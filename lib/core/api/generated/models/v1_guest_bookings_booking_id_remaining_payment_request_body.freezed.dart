// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'v1_guest_bookings_booking_id_remaining_payment_request_body.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$V1GuestBookingsBookingIdRemainingPaymentRequestBody {

@JsonKey(name: 'idempotency_key') String get idempotencyKey;
/// Create a copy of V1GuestBookingsBookingIdRemainingPaymentRequestBody
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$V1GuestBookingsBookingIdRemainingPaymentRequestBodyCopyWith<V1GuestBookingsBookingIdRemainingPaymentRequestBody> get copyWith => _$V1GuestBookingsBookingIdRemainingPaymentRequestBodyCopyWithImpl<V1GuestBookingsBookingIdRemainingPaymentRequestBody>(this as V1GuestBookingsBookingIdRemainingPaymentRequestBody, _$identity);

  /// Serializes this V1GuestBookingsBookingIdRemainingPaymentRequestBody to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is V1GuestBookingsBookingIdRemainingPaymentRequestBody&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,idempotencyKey);

@override
String toString() {
  return 'V1GuestBookingsBookingIdRemainingPaymentRequestBody(idempotencyKey: $idempotencyKey)';
}


}

/// @nodoc
abstract mixin class $V1GuestBookingsBookingIdRemainingPaymentRequestBodyCopyWith<$Res>  {
  factory $V1GuestBookingsBookingIdRemainingPaymentRequestBodyCopyWith(V1GuestBookingsBookingIdRemainingPaymentRequestBody value, $Res Function(V1GuestBookingsBookingIdRemainingPaymentRequestBody) _then) = _$V1GuestBookingsBookingIdRemainingPaymentRequestBodyCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'idempotency_key') String idempotencyKey
});




}
/// @nodoc
class _$V1GuestBookingsBookingIdRemainingPaymentRequestBodyCopyWithImpl<$Res>
    implements $V1GuestBookingsBookingIdRemainingPaymentRequestBodyCopyWith<$Res> {
  _$V1GuestBookingsBookingIdRemainingPaymentRequestBodyCopyWithImpl(this._self, this._then);

  final V1GuestBookingsBookingIdRemainingPaymentRequestBody _self;
  final $Res Function(V1GuestBookingsBookingIdRemainingPaymentRequestBody) _then;

/// Create a copy of V1GuestBookingsBookingIdRemainingPaymentRequestBody
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? idempotencyKey = null,}) {
  return _then(_self.copyWith(
idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [V1GuestBookingsBookingIdRemainingPaymentRequestBody].
extension V1GuestBookingsBookingIdRemainingPaymentRequestBodyPatterns on V1GuestBookingsBookingIdRemainingPaymentRequestBody {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _V1GuestBookingsBookingIdRemainingPaymentRequestBody value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _V1GuestBookingsBookingIdRemainingPaymentRequestBody() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _V1GuestBookingsBookingIdRemainingPaymentRequestBody value)  $default,){
final _that = this;
switch (_that) {
case _V1GuestBookingsBookingIdRemainingPaymentRequestBody():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _V1GuestBookingsBookingIdRemainingPaymentRequestBody value)?  $default,){
final _that = this;
switch (_that) {
case _V1GuestBookingsBookingIdRemainingPaymentRequestBody() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'idempotency_key')  String idempotencyKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _V1GuestBookingsBookingIdRemainingPaymentRequestBody() when $default != null:
return $default(_that.idempotencyKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'idempotency_key')  String idempotencyKey)  $default,) {final _that = this;
switch (_that) {
case _V1GuestBookingsBookingIdRemainingPaymentRequestBody():
return $default(_that.idempotencyKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'idempotency_key')  String idempotencyKey)?  $default,) {final _that = this;
switch (_that) {
case _V1GuestBookingsBookingIdRemainingPaymentRequestBody() when $default != null:
return $default(_that.idempotencyKey);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _V1GuestBookingsBookingIdRemainingPaymentRequestBody implements V1GuestBookingsBookingIdRemainingPaymentRequestBody {
  const _V1GuestBookingsBookingIdRemainingPaymentRequestBody({@JsonKey(name: 'idempotency_key') required this.idempotencyKey});
  factory _V1GuestBookingsBookingIdRemainingPaymentRequestBody.fromJson(Map<String, dynamic> json) => _$V1GuestBookingsBookingIdRemainingPaymentRequestBodyFromJson(json);

@override@JsonKey(name: 'idempotency_key') final  String idempotencyKey;

/// Create a copy of V1GuestBookingsBookingIdRemainingPaymentRequestBody
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$V1GuestBookingsBookingIdRemainingPaymentRequestBodyCopyWith<_V1GuestBookingsBookingIdRemainingPaymentRequestBody> get copyWith => __$V1GuestBookingsBookingIdRemainingPaymentRequestBodyCopyWithImpl<_V1GuestBookingsBookingIdRemainingPaymentRequestBody>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$V1GuestBookingsBookingIdRemainingPaymentRequestBodyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _V1GuestBookingsBookingIdRemainingPaymentRequestBody&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,idempotencyKey);

@override
String toString() {
  return 'V1GuestBookingsBookingIdRemainingPaymentRequestBody(idempotencyKey: $idempotencyKey)';
}


}

/// @nodoc
abstract mixin class _$V1GuestBookingsBookingIdRemainingPaymentRequestBodyCopyWith<$Res> implements $V1GuestBookingsBookingIdRemainingPaymentRequestBodyCopyWith<$Res> {
  factory _$V1GuestBookingsBookingIdRemainingPaymentRequestBodyCopyWith(_V1GuestBookingsBookingIdRemainingPaymentRequestBody value, $Res Function(_V1GuestBookingsBookingIdRemainingPaymentRequestBody) _then) = __$V1GuestBookingsBookingIdRemainingPaymentRequestBodyCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'idempotency_key') String idempotencyKey
});




}
/// @nodoc
class __$V1GuestBookingsBookingIdRemainingPaymentRequestBodyCopyWithImpl<$Res>
    implements _$V1GuestBookingsBookingIdRemainingPaymentRequestBodyCopyWith<$Res> {
  __$V1GuestBookingsBookingIdRemainingPaymentRequestBodyCopyWithImpl(this._self, this._then);

  final _V1GuestBookingsBookingIdRemainingPaymentRequestBody _self;
  final $Res Function(_V1GuestBookingsBookingIdRemainingPaymentRequestBody) _then;

/// Create a copy of V1GuestBookingsBookingIdRemainingPaymentRequestBody
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? idempotencyKey = null,}) {
  return _then(_V1GuestBookingsBookingIdRemainingPaymentRequestBody(
idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'v1_guest_bookings_start_payment_request_body.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$V1GuestBookingsStartPaymentRequestBody {

@JsonKey(name: 'quote_id') String get quoteId;@JsonKey(name: 'terms_hash') String get termsHash;@JsonKey(name: 'idempotency_key') String get idempotencyKey;
/// Create a copy of V1GuestBookingsStartPaymentRequestBody
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$V1GuestBookingsStartPaymentRequestBodyCopyWith<V1GuestBookingsStartPaymentRequestBody> get copyWith => _$V1GuestBookingsStartPaymentRequestBodyCopyWithImpl<V1GuestBookingsStartPaymentRequestBody>(this as V1GuestBookingsStartPaymentRequestBody, _$identity);

  /// Serializes this V1GuestBookingsStartPaymentRequestBody to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is V1GuestBookingsStartPaymentRequestBody&&(identical(other.quoteId, quoteId) || other.quoteId == quoteId)&&(identical(other.termsHash, termsHash) || other.termsHash == termsHash)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quoteId,termsHash,idempotencyKey);

@override
String toString() {
  return 'V1GuestBookingsStartPaymentRequestBody(quoteId: $quoteId, termsHash: $termsHash, idempotencyKey: $idempotencyKey)';
}


}

/// @nodoc
abstract mixin class $V1GuestBookingsStartPaymentRequestBodyCopyWith<$Res>  {
  factory $V1GuestBookingsStartPaymentRequestBodyCopyWith(V1GuestBookingsStartPaymentRequestBody value, $Res Function(V1GuestBookingsStartPaymentRequestBody) _then) = _$V1GuestBookingsStartPaymentRequestBodyCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'quote_id') String quoteId,@JsonKey(name: 'terms_hash') String termsHash,@JsonKey(name: 'idempotency_key') String idempotencyKey
});




}
/// @nodoc
class _$V1GuestBookingsStartPaymentRequestBodyCopyWithImpl<$Res>
    implements $V1GuestBookingsStartPaymentRequestBodyCopyWith<$Res> {
  _$V1GuestBookingsStartPaymentRequestBodyCopyWithImpl(this._self, this._then);

  final V1GuestBookingsStartPaymentRequestBody _self;
  final $Res Function(V1GuestBookingsStartPaymentRequestBody) _then;

/// Create a copy of V1GuestBookingsStartPaymentRequestBody
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quoteId = null,Object? termsHash = null,Object? idempotencyKey = null,}) {
  return _then(_self.copyWith(
quoteId: null == quoteId ? _self.quoteId : quoteId // ignore: cast_nullable_to_non_nullable
as String,termsHash: null == termsHash ? _self.termsHash : termsHash // ignore: cast_nullable_to_non_nullable
as String,idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [V1GuestBookingsStartPaymentRequestBody].
extension V1GuestBookingsStartPaymentRequestBodyPatterns on V1GuestBookingsStartPaymentRequestBody {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _V1GuestBookingsStartPaymentRequestBody value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _V1GuestBookingsStartPaymentRequestBody() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _V1GuestBookingsStartPaymentRequestBody value)  $default,){
final _that = this;
switch (_that) {
case _V1GuestBookingsStartPaymentRequestBody():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _V1GuestBookingsStartPaymentRequestBody value)?  $default,){
final _that = this;
switch (_that) {
case _V1GuestBookingsStartPaymentRequestBody() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'quote_id')  String quoteId, @JsonKey(name: 'terms_hash')  String termsHash, @JsonKey(name: 'idempotency_key')  String idempotencyKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _V1GuestBookingsStartPaymentRequestBody() when $default != null:
return $default(_that.quoteId,_that.termsHash,_that.idempotencyKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'quote_id')  String quoteId, @JsonKey(name: 'terms_hash')  String termsHash, @JsonKey(name: 'idempotency_key')  String idempotencyKey)  $default,) {final _that = this;
switch (_that) {
case _V1GuestBookingsStartPaymentRequestBody():
return $default(_that.quoteId,_that.termsHash,_that.idempotencyKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'quote_id')  String quoteId, @JsonKey(name: 'terms_hash')  String termsHash, @JsonKey(name: 'idempotency_key')  String idempotencyKey)?  $default,) {final _that = this;
switch (_that) {
case _V1GuestBookingsStartPaymentRequestBody() when $default != null:
return $default(_that.quoteId,_that.termsHash,_that.idempotencyKey);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _V1GuestBookingsStartPaymentRequestBody implements V1GuestBookingsStartPaymentRequestBody {
  const _V1GuestBookingsStartPaymentRequestBody({@JsonKey(name: 'quote_id') required this.quoteId, @JsonKey(name: 'terms_hash') required this.termsHash, @JsonKey(name: 'idempotency_key') required this.idempotencyKey});
  factory _V1GuestBookingsStartPaymentRequestBody.fromJson(Map<String, dynamic> json) => _$V1GuestBookingsStartPaymentRequestBodyFromJson(json);

@override@JsonKey(name: 'quote_id') final  String quoteId;
@override@JsonKey(name: 'terms_hash') final  String termsHash;
@override@JsonKey(name: 'idempotency_key') final  String idempotencyKey;

/// Create a copy of V1GuestBookingsStartPaymentRequestBody
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$V1GuestBookingsStartPaymentRequestBodyCopyWith<_V1GuestBookingsStartPaymentRequestBody> get copyWith => __$V1GuestBookingsStartPaymentRequestBodyCopyWithImpl<_V1GuestBookingsStartPaymentRequestBody>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$V1GuestBookingsStartPaymentRequestBodyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _V1GuestBookingsStartPaymentRequestBody&&(identical(other.quoteId, quoteId) || other.quoteId == quoteId)&&(identical(other.termsHash, termsHash) || other.termsHash == termsHash)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quoteId,termsHash,idempotencyKey);

@override
String toString() {
  return 'V1GuestBookingsStartPaymentRequestBody(quoteId: $quoteId, termsHash: $termsHash, idempotencyKey: $idempotencyKey)';
}


}

/// @nodoc
abstract mixin class _$V1GuestBookingsStartPaymentRequestBodyCopyWith<$Res> implements $V1GuestBookingsStartPaymentRequestBodyCopyWith<$Res> {
  factory _$V1GuestBookingsStartPaymentRequestBodyCopyWith(_V1GuestBookingsStartPaymentRequestBody value, $Res Function(_V1GuestBookingsStartPaymentRequestBody) _then) = __$V1GuestBookingsStartPaymentRequestBodyCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'quote_id') String quoteId,@JsonKey(name: 'terms_hash') String termsHash,@JsonKey(name: 'idempotency_key') String idempotencyKey
});




}
/// @nodoc
class __$V1GuestBookingsStartPaymentRequestBodyCopyWithImpl<$Res>
    implements _$V1GuestBookingsStartPaymentRequestBodyCopyWith<$Res> {
  __$V1GuestBookingsStartPaymentRequestBodyCopyWithImpl(this._self, this._then);

  final _V1GuestBookingsStartPaymentRequestBody _self;
  final $Res Function(_V1GuestBookingsStartPaymentRequestBody) _then;

/// Create a copy of V1GuestBookingsStartPaymentRequestBody
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quoteId = null,Object? termsHash = null,Object? idempotencyKey = null,}) {
  return _then(_V1GuestBookingsStartPaymentRequestBody(
quoteId: null == quoteId ? _self.quoteId : quoteId // ignore: cast_nullable_to_non_nullable
as String,termsHash: null == termsHash ? _self.termsHash : termsHash // ignore: cast_nullable_to_non_nullable
as String,idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

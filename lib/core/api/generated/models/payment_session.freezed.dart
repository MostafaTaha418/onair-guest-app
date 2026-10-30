// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaymentSession {

@JsonKey(name: 'booking_id') String get bookingId;@JsonKey(name: 'payment_id') String get paymentId;@JsonKey(name: 'payment_url') String get paymentUrl;@JsonKey(name: 'payment_url_expires_at') DateTime get paymentUrlExpiresAt;/// Display only; computed on the server
@JsonKey(name: 'amount_minor') int get amountMinor; PaymentSessionCurrency get currency;
/// Create a copy of PaymentSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentSessionCopyWith<PaymentSession> get copyWith => _$PaymentSessionCopyWithImpl<PaymentSession>(this as PaymentSession, _$identity);

  /// Serializes this PaymentSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentSession&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.paymentUrl, paymentUrl) || other.paymentUrl == paymentUrl)&&(identical(other.paymentUrlExpiresAt, paymentUrlExpiresAt) || other.paymentUrlExpiresAt == paymentUrlExpiresAt)&&(identical(other.amountMinor, amountMinor) || other.amountMinor == amountMinor)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bookingId,paymentId,paymentUrl,paymentUrlExpiresAt,amountMinor,currency);

@override
String toString() {
  return 'PaymentSession(bookingId: $bookingId, paymentId: $paymentId, paymentUrl: $paymentUrl, paymentUrlExpiresAt: $paymentUrlExpiresAt, amountMinor: $amountMinor, currency: $currency)';
}


}

/// @nodoc
abstract mixin class $PaymentSessionCopyWith<$Res>  {
  factory $PaymentSessionCopyWith(PaymentSession value, $Res Function(PaymentSession) _then) = _$PaymentSessionCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'booking_id') String bookingId,@JsonKey(name: 'payment_id') String paymentId,@JsonKey(name: 'payment_url') String paymentUrl,@JsonKey(name: 'payment_url_expires_at') DateTime paymentUrlExpiresAt,@JsonKey(name: 'amount_minor') int amountMinor, PaymentSessionCurrency currency
});




}
/// @nodoc
class _$PaymentSessionCopyWithImpl<$Res>
    implements $PaymentSessionCopyWith<$Res> {
  _$PaymentSessionCopyWithImpl(this._self, this._then);

  final PaymentSession _self;
  final $Res Function(PaymentSession) _then;

/// Create a copy of PaymentSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bookingId = null,Object? paymentId = null,Object? paymentUrl = null,Object? paymentUrlExpiresAt = null,Object? amountMinor = null,Object? currency = null,}) {
  return _then(_self.copyWith(
bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String,paymentId: null == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String,paymentUrl: null == paymentUrl ? _self.paymentUrl : paymentUrl // ignore: cast_nullable_to_non_nullable
as String,paymentUrlExpiresAt: null == paymentUrlExpiresAt ? _self.paymentUrlExpiresAt : paymentUrlExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,amountMinor: null == amountMinor ? _self.amountMinor : amountMinor // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as PaymentSessionCurrency,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentSession].
extension PaymentSessionPatterns on PaymentSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentSession value)  $default,){
final _that = this;
switch (_that) {
case _PaymentSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentSession value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'booking_id')  String bookingId, @JsonKey(name: 'payment_id')  String paymentId, @JsonKey(name: 'payment_url')  String paymentUrl, @JsonKey(name: 'payment_url_expires_at')  DateTime paymentUrlExpiresAt, @JsonKey(name: 'amount_minor')  int amountMinor,  PaymentSessionCurrency currency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentSession() when $default != null:
return $default(_that.bookingId,_that.paymentId,_that.paymentUrl,_that.paymentUrlExpiresAt,_that.amountMinor,_that.currency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'booking_id')  String bookingId, @JsonKey(name: 'payment_id')  String paymentId, @JsonKey(name: 'payment_url')  String paymentUrl, @JsonKey(name: 'payment_url_expires_at')  DateTime paymentUrlExpiresAt, @JsonKey(name: 'amount_minor')  int amountMinor,  PaymentSessionCurrency currency)  $default,) {final _that = this;
switch (_that) {
case _PaymentSession():
return $default(_that.bookingId,_that.paymentId,_that.paymentUrl,_that.paymentUrlExpiresAt,_that.amountMinor,_that.currency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'booking_id')  String bookingId, @JsonKey(name: 'payment_id')  String paymentId, @JsonKey(name: 'payment_url')  String paymentUrl, @JsonKey(name: 'payment_url_expires_at')  DateTime paymentUrlExpiresAt, @JsonKey(name: 'amount_minor')  int amountMinor,  PaymentSessionCurrency currency)?  $default,) {final _that = this;
switch (_that) {
case _PaymentSession() when $default != null:
return $default(_that.bookingId,_that.paymentId,_that.paymentUrl,_that.paymentUrlExpiresAt,_that.amountMinor,_that.currency);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentSession implements PaymentSession {
  const _PaymentSession({@JsonKey(name: 'booking_id') required this.bookingId, @JsonKey(name: 'payment_id') required this.paymentId, @JsonKey(name: 'payment_url') required this.paymentUrl, @JsonKey(name: 'payment_url_expires_at') required this.paymentUrlExpiresAt, @JsonKey(name: 'amount_minor') required this.amountMinor, required this.currency});
  factory _PaymentSession.fromJson(Map<String, dynamic> json) => _$PaymentSessionFromJson(json);

@override@JsonKey(name: 'booking_id') final  String bookingId;
@override@JsonKey(name: 'payment_id') final  String paymentId;
@override@JsonKey(name: 'payment_url') final  String paymentUrl;
@override@JsonKey(name: 'payment_url_expires_at') final  DateTime paymentUrlExpiresAt;
/// Display only; computed on the server
@override@JsonKey(name: 'amount_minor') final  int amountMinor;
@override final  PaymentSessionCurrency currency;

/// Create a copy of PaymentSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentSessionCopyWith<_PaymentSession> get copyWith => __$PaymentSessionCopyWithImpl<_PaymentSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentSession&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.paymentUrl, paymentUrl) || other.paymentUrl == paymentUrl)&&(identical(other.paymentUrlExpiresAt, paymentUrlExpiresAt) || other.paymentUrlExpiresAt == paymentUrlExpiresAt)&&(identical(other.amountMinor, amountMinor) || other.amountMinor == amountMinor)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bookingId,paymentId,paymentUrl,paymentUrlExpiresAt,amountMinor,currency);

@override
String toString() {
  return 'PaymentSession(bookingId: $bookingId, paymentId: $paymentId, paymentUrl: $paymentUrl, paymentUrlExpiresAt: $paymentUrlExpiresAt, amountMinor: $amountMinor, currency: $currency)';
}


}

/// @nodoc
abstract mixin class _$PaymentSessionCopyWith<$Res> implements $PaymentSessionCopyWith<$Res> {
  factory _$PaymentSessionCopyWith(_PaymentSession value, $Res Function(_PaymentSession) _then) = __$PaymentSessionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'booking_id') String bookingId,@JsonKey(name: 'payment_id') String paymentId,@JsonKey(name: 'payment_url') String paymentUrl,@JsonKey(name: 'payment_url_expires_at') DateTime paymentUrlExpiresAt,@JsonKey(name: 'amount_minor') int amountMinor, PaymentSessionCurrency currency
});




}
/// @nodoc
class __$PaymentSessionCopyWithImpl<$Res>
    implements _$PaymentSessionCopyWith<$Res> {
  __$PaymentSessionCopyWithImpl(this._self, this._then);

  final _PaymentSession _self;
  final $Res Function(_PaymentSession) _then;

/// Create a copy of PaymentSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bookingId = null,Object? paymentId = null,Object? paymentUrl = null,Object? paymentUrlExpiresAt = null,Object? amountMinor = null,Object? currency = null,}) {
  return _then(_PaymentSession(
bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String,paymentId: null == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String,paymentUrl: null == paymentUrl ? _self.paymentUrl : paymentUrl // ignore: cast_nullable_to_non_nullable
as String,paymentUrlExpiresAt: null == paymentUrlExpiresAt ? _self.paymentUrlExpiresAt : paymentUrlExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,amountMinor: null == amountMinor ? _self.amountMinor : amountMinor // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as PaymentSessionCurrency,
  ));
}


}

// dart format on

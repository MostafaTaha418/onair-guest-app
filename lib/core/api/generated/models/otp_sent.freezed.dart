// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'otp_sent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OtpSent {

/// Where the code went (S005 A8).
 OtpSentChannel get channel;/// Masked destination: the email for `email`, the phone for `whatsapp` (e.g. "+20 10•• ••• 678").
@JsonKey(name: 'masked_target') String get maskedTarget;@JsonKey(name: 'expires_at') DateTime get expiresAt;@JsonKey(name: 'server_time') DateTime get serverTime;@JsonKey(name: 'next_send_at') DateTime? get nextSendAt;@JsonKey(name: 'blocked_until') DateTime? get blockedUntil;/// Masked email, e.g. "a***@gmail.com"
@JsonKey(name: 'sent_to_masked') String? get sentToMasked;@JsonKey(name: 'retry_after_seconds') int? get retryAfterSeconds;
/// Create a copy of OtpSent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtpSentCopyWith<OtpSent> get copyWith => _$OtpSentCopyWithImpl<OtpSent>(this as OtpSent, _$identity);

  /// Serializes this OtpSent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpSent&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.maskedTarget, maskedTarget) || other.maskedTarget == maskedTarget)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime)&&(identical(other.nextSendAt, nextSendAt) || other.nextSendAt == nextSendAt)&&(identical(other.blockedUntil, blockedUntil) || other.blockedUntil == blockedUntil)&&(identical(other.sentToMasked, sentToMasked) || other.sentToMasked == sentToMasked)&&(identical(other.retryAfterSeconds, retryAfterSeconds) || other.retryAfterSeconds == retryAfterSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,channel,maskedTarget,expiresAt,serverTime,nextSendAt,blockedUntil,sentToMasked,retryAfterSeconds);

@override
String toString() {
  return 'OtpSent(channel: $channel, maskedTarget: $maskedTarget, expiresAt: $expiresAt, serverTime: $serverTime, nextSendAt: $nextSendAt, blockedUntil: $blockedUntil, sentToMasked: $sentToMasked, retryAfterSeconds: $retryAfterSeconds)';
}


}

/// @nodoc
abstract mixin class $OtpSentCopyWith<$Res>  {
  factory $OtpSentCopyWith(OtpSent value, $Res Function(OtpSent) _then) = _$OtpSentCopyWithImpl;
@useResult
$Res call({
 OtpSentChannel channel,@JsonKey(name: 'masked_target') String maskedTarget,@JsonKey(name: 'expires_at') DateTime expiresAt,@JsonKey(name: 'server_time') DateTime serverTime,@JsonKey(name: 'next_send_at') DateTime? nextSendAt,@JsonKey(name: 'blocked_until') DateTime? blockedUntil,@JsonKey(name: 'sent_to_masked') String? sentToMasked,@JsonKey(name: 'retry_after_seconds') int? retryAfterSeconds
});




}
/// @nodoc
class _$OtpSentCopyWithImpl<$Res>
    implements $OtpSentCopyWith<$Res> {
  _$OtpSentCopyWithImpl(this._self, this._then);

  final OtpSent _self;
  final $Res Function(OtpSent) _then;

/// Create a copy of OtpSent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? channel = null,Object? maskedTarget = null,Object? expiresAt = null,Object? serverTime = null,Object? nextSendAt = freezed,Object? blockedUntil = freezed,Object? sentToMasked = freezed,Object? retryAfterSeconds = freezed,}) {
  return _then(_self.copyWith(
channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as OtpSentChannel,maskedTarget: null == maskedTarget ? _self.maskedTarget : maskedTarget // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime,nextSendAt: freezed == nextSendAt ? _self.nextSendAt : nextSendAt // ignore: cast_nullable_to_non_nullable
as DateTime?,blockedUntil: freezed == blockedUntil ? _self.blockedUntil : blockedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,sentToMasked: freezed == sentToMasked ? _self.sentToMasked : sentToMasked // ignore: cast_nullable_to_non_nullable
as String?,retryAfterSeconds: freezed == retryAfterSeconds ? _self.retryAfterSeconds : retryAfterSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [OtpSent].
extension OtpSentPatterns on OtpSent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OtpSent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OtpSent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OtpSent value)  $default,){
final _that = this;
switch (_that) {
case _OtpSent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OtpSent value)?  $default,){
final _that = this;
switch (_that) {
case _OtpSent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OtpSentChannel channel, @JsonKey(name: 'masked_target')  String maskedTarget, @JsonKey(name: 'expires_at')  DateTime expiresAt, @JsonKey(name: 'server_time')  DateTime serverTime, @JsonKey(name: 'next_send_at')  DateTime? nextSendAt, @JsonKey(name: 'blocked_until')  DateTime? blockedUntil, @JsonKey(name: 'sent_to_masked')  String? sentToMasked, @JsonKey(name: 'retry_after_seconds')  int? retryAfterSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OtpSent() when $default != null:
return $default(_that.channel,_that.maskedTarget,_that.expiresAt,_that.serverTime,_that.nextSendAt,_that.blockedUntil,_that.sentToMasked,_that.retryAfterSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OtpSentChannel channel, @JsonKey(name: 'masked_target')  String maskedTarget, @JsonKey(name: 'expires_at')  DateTime expiresAt, @JsonKey(name: 'server_time')  DateTime serverTime, @JsonKey(name: 'next_send_at')  DateTime? nextSendAt, @JsonKey(name: 'blocked_until')  DateTime? blockedUntil, @JsonKey(name: 'sent_to_masked')  String? sentToMasked, @JsonKey(name: 'retry_after_seconds')  int? retryAfterSeconds)  $default,) {final _that = this;
switch (_that) {
case _OtpSent():
return $default(_that.channel,_that.maskedTarget,_that.expiresAt,_that.serverTime,_that.nextSendAt,_that.blockedUntil,_that.sentToMasked,_that.retryAfterSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OtpSentChannel channel, @JsonKey(name: 'masked_target')  String maskedTarget, @JsonKey(name: 'expires_at')  DateTime expiresAt, @JsonKey(name: 'server_time')  DateTime serverTime, @JsonKey(name: 'next_send_at')  DateTime? nextSendAt, @JsonKey(name: 'blocked_until')  DateTime? blockedUntil, @JsonKey(name: 'sent_to_masked')  String? sentToMasked, @JsonKey(name: 'retry_after_seconds')  int? retryAfterSeconds)?  $default,) {final _that = this;
switch (_that) {
case _OtpSent() when $default != null:
return $default(_that.channel,_that.maskedTarget,_that.expiresAt,_that.serverTime,_that.nextSendAt,_that.blockedUntil,_that.sentToMasked,_that.retryAfterSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OtpSent implements OtpSent {
  const _OtpSent({required this.channel, @JsonKey(name: 'masked_target') required this.maskedTarget, @JsonKey(name: 'expires_at') required this.expiresAt, @JsonKey(name: 'server_time') required this.serverTime, @JsonKey(name: 'next_send_at') this.nextSendAt, @JsonKey(name: 'blocked_until') this.blockedUntil, @JsonKey(name: 'sent_to_masked') this.sentToMasked, @JsonKey(name: 'retry_after_seconds') this.retryAfterSeconds});
  factory _OtpSent.fromJson(Map<String, dynamic> json) => _$OtpSentFromJson(json);

/// Where the code went (S005 A8).
@override final  OtpSentChannel channel;
/// Masked destination: the email for `email`, the phone for `whatsapp` (e.g. "+20 10•• ••• 678").
@override@JsonKey(name: 'masked_target') final  String maskedTarget;
@override@JsonKey(name: 'expires_at') final  DateTime expiresAt;
@override@JsonKey(name: 'server_time') final  DateTime serverTime;
@override@JsonKey(name: 'next_send_at') final  DateTime? nextSendAt;
@override@JsonKey(name: 'blocked_until') final  DateTime? blockedUntil;
/// Masked email, e.g. "a***@gmail.com"
@override@JsonKey(name: 'sent_to_masked') final  String? sentToMasked;
@override@JsonKey(name: 'retry_after_seconds') final  int? retryAfterSeconds;

/// Create a copy of OtpSent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OtpSentCopyWith<_OtpSent> get copyWith => __$OtpSentCopyWithImpl<_OtpSent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OtpSentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OtpSent&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.maskedTarget, maskedTarget) || other.maskedTarget == maskedTarget)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime)&&(identical(other.nextSendAt, nextSendAt) || other.nextSendAt == nextSendAt)&&(identical(other.blockedUntil, blockedUntil) || other.blockedUntil == blockedUntil)&&(identical(other.sentToMasked, sentToMasked) || other.sentToMasked == sentToMasked)&&(identical(other.retryAfterSeconds, retryAfterSeconds) || other.retryAfterSeconds == retryAfterSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,channel,maskedTarget,expiresAt,serverTime,nextSendAt,blockedUntil,sentToMasked,retryAfterSeconds);

@override
String toString() {
  return 'OtpSent(channel: $channel, maskedTarget: $maskedTarget, expiresAt: $expiresAt, serverTime: $serverTime, nextSendAt: $nextSendAt, blockedUntil: $blockedUntil, sentToMasked: $sentToMasked, retryAfterSeconds: $retryAfterSeconds)';
}


}

/// @nodoc
abstract mixin class _$OtpSentCopyWith<$Res> implements $OtpSentCopyWith<$Res> {
  factory _$OtpSentCopyWith(_OtpSent value, $Res Function(_OtpSent) _then) = __$OtpSentCopyWithImpl;
@override @useResult
$Res call({
 OtpSentChannel channel,@JsonKey(name: 'masked_target') String maskedTarget,@JsonKey(name: 'expires_at') DateTime expiresAt,@JsonKey(name: 'server_time') DateTime serverTime,@JsonKey(name: 'next_send_at') DateTime? nextSendAt,@JsonKey(name: 'blocked_until') DateTime? blockedUntil,@JsonKey(name: 'sent_to_masked') String? sentToMasked,@JsonKey(name: 'retry_after_seconds') int? retryAfterSeconds
});




}
/// @nodoc
class __$OtpSentCopyWithImpl<$Res>
    implements _$OtpSentCopyWith<$Res> {
  __$OtpSentCopyWithImpl(this._self, this._then);

  final _OtpSent _self;
  final $Res Function(_OtpSent) _then;

/// Create a copy of OtpSent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? channel = null,Object? maskedTarget = null,Object? expiresAt = null,Object? serverTime = null,Object? nextSendAt = freezed,Object? blockedUntil = freezed,Object? sentToMasked = freezed,Object? retryAfterSeconds = freezed,}) {
  return _then(_OtpSent(
channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as OtpSentChannel,maskedTarget: null == maskedTarget ? _self.maskedTarget : maskedTarget // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime,nextSendAt: freezed == nextSendAt ? _self.nextSendAt : nextSendAt // ignore: cast_nullable_to_non_nullable
as DateTime?,blockedUntil: freezed == blockedUntil ? _self.blockedUntil : blockedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,sentToMasked: freezed == sentToMasked ? _self.sentToMasked : sentToMasked // ignore: cast_nullable_to_non_nullable
as String?,retryAfterSeconds: freezed == retryAfterSeconds ? _self.retryAfterSeconds : retryAfterSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

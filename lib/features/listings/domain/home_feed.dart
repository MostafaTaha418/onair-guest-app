import 'package:flutter/foundation.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';
import 'package:on_air/features/listings/domain/listing_image.dart';

/// One Home section: the server reports section failures instead of failing
/// the whole feed (research R6).
sealed class FeedSection<T> {
  const FeedSection();
}

@immutable
final class FeedSectionReady<T> extends FeedSection<T> {
  const FeedSectionReady(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      other is FeedSectionReady<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

@immutable
final class FeedSectionFailed<T> extends FeedSection<T> {
  const FeedSectionFailed(this.errorCode, this.requestId);

  final String errorCode;
  final String? requestId;

  @override
  bool operator ==(Object other) =>
      other is FeedSectionFailed<T> &&
      other.errorCode == errorCode &&
      other.requestId == requestId;

  @override
  int get hashCode => Object.hash(errorCode, requestId);
}

@immutable
final class AreaTile {
  const AreaTile({
    required this.locationId,
    required this.name,
    required this.listingCount,
    required this.image,
  });

  factory AreaTile.fromJson(Map<String, dynamic> json) => AreaTile(
    locationId: json['location_id'] as String,
    name: json['name'] as String,
    listingCount: json['listing_count'] as int? ?? 0,
    image: json['image'] == null
        ? null
        : ListingImage.fromJson(
            Map<String, dynamic>.from(json['image'] as Map),
          ),
  );

  final String locationId;
  final String name;
  final int listingCount;
  final ListingImage? image;

  Map<String, dynamic> toJson() => {
    'location_id': locationId,
    'name': name,
    'listing_count': listingCount,
    'image': image == null
        ? null
        : {
            'variants': [
              for (final variant in image!.variants)
                {'width': variant.width, 'url': variant.url.toString()},
            ],
            'blurhash': image!.blurhash,
          },
  };

  @override
  bool operator ==(Object other) =>
      other is AreaTile &&
      other.locationId == locationId &&
      other.name == name &&
      other.listingCount == listingCount &&
      other.image == image;

  @override
  int get hashCode => Object.hash(locationId, name, listingCount, image);
}

@immutable
final class UpcomingBookingCard {
  const UpcomingBookingCard({
    required this.bookingId,
    required this.propertyTitle,
    required this.checkIn,
    required this.checkOut,
    required this.status,
  });

  factory UpcomingBookingCard.fromJson(Map<String, dynamic> json) =>
      UpcomingBookingCard(
        bookingId: json['booking_id'] as String,
        propertyTitle: json['property_title'] as String,
        checkIn: DateOnly.parse(json['check_in'] as String),
        checkOut: DateOnly.parse(json['check_out'] as String),
        status: json['status'] as String,
      );

  final String bookingId;
  final String propertyTitle;
  final DateOnly checkIn;
  final DateOnly checkOut;

  /// Server status key, mapped through G0's status chips.
  final String status;

  @override
  bool operator ==(Object other) =>
      other is UpcomingBookingCard &&
      other.bookingId == bookingId &&
      other.propertyTitle == propertyTitle &&
      other.checkIn == checkIn &&
      other.checkOut == checkOut &&
      other.status == status;

  @override
  int get hashCode =>
      Object.hash(bookingId, propertyTitle, checkIn, checkOut, status);
}

/// The Home feed. [upcomingBooking] is personal: it is fetched fresh for
/// signed-in guests and never written to the disk cache (research R6).
@immutable
final class HomeFeed {
  const HomeFeed({
    required this.referenceVersion,
    required this.areas,
    required this.suggested,
    required this.newest,
    required this.upcomingBooking,
    required this.fetchedAt,
  });

  factory HomeFeed.fromJson(Map<String, dynamic> json) => HomeFeed(
    referenceVersion: json['reference_version'] as String,
    areas: _listSection(json['areas'], AreaTile.fromJson),
    suggested: _listSection(json['suggested'], ListingCard.fromJson),
    newest: _listSection(json['newest'], ListingCard.fromJson),
    upcomingBooking: _upcomingSection(json['upcoming_booking']),
    fetchedAt: _parseFetchedAt(json['fetched_at']),
  );

  /// Restores the public disk-cache document: no upcoming booking exists in
  /// it, so the section is ready-null.
  factory HomeFeed.fromPublicJson(Map<String, dynamic> json) => HomeFeed(
    referenceVersion: json['reference_version'] as String,
    areas: _listSection(json['areas'], AreaTile.fromJson),
    suggested: _listSection(json['suggested'], ListingCard.fromJson),
    newest: _listSection(json['newest'], ListingCard.fromJson),
    upcomingBooking: const FeedSectionReady(null),
    fetchedAt: _parseFetchedAt(json['fetched_at']),
  );

  final String referenceVersion;
  final FeedSection<List<AreaTile>> areas;
  final FeedSection<List<ListingCard>> suggested;
  final FeedSection<List<ListingCard>> newest;
  final FeedSection<UpcomingBookingCard?> upcomingBooking;
  final DateTime fetchedAt;

  /// The disk-cache document: public sections only, never the booking.
  Map<String, dynamic> toPublicJson() => {
    'reference_version': referenceVersion,
    'areas': _sectionToJson(areas, _areaTileJson),
    'suggested': _sectionToJson(suggested, _listingCardJson),
    'newest': _sectionToJson(newest, _listingCardJson),
    'fetched_at': fetchedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is HomeFeed &&
      other.referenceVersion == referenceVersion &&
      other.areas == areas &&
      other.suggested == suggested &&
      other.newest == newest &&
      other.upcomingBooking == upcomingBooking &&
      other.fetchedAt == fetchedAt;

  @override
  int get hashCode => Object.hash(
    referenceVersion,
    areas,
    suggested,
    newest,
    upcomingBooking,
    fetchedAt,
  );
}

DateTime _parseFetchedAt(Object? value) =>
    value is String ? DateTime.parse(value) : DateTime.now().toUtc();

FeedSection<List<T>> _listSection<T>(
  Object? raw,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (raw is! Map) return const FeedSectionFailed('INTERNAL', null);
  if (raw['status'] != 'ready') {
    return FeedSectionFailed(
      raw['error_code'] as String? ?? 'INTERNAL',
      raw['request_id'] as String?,
    );
  }
  return FeedSectionReady([
    for (final item in raw['items'] as List? ?? const [])
      fromJson(Map<String, dynamic>.from(item as Map)),
  ]);
}

FeedSection<UpcomingBookingCard?> _upcomingSection(Object? raw) {
  if (raw is! Map) return const FeedSectionFailed('INTERNAL', null);
  if (raw['status'] != 'ready') {
    return FeedSectionFailed(
      raw['error_code'] as String? ?? 'INTERNAL',
      raw['request_id'] as String?,
    );
  }
  final item = raw['item'];
  return FeedSectionReady(
    item == null
        ? null
        : UpcomingBookingCard.fromJson(Map<String, dynamic>.from(item as Map)),
  );
}

Map<String, dynamic> _areaTileJson(AreaTile tile) => tile.toJson();

Map<String, dynamic> _listingCardJson(ListingCard card) => card.toJson();

Map<String, dynamic> _sectionToJson<T>(
  FeedSection<List<T>> section,
  Map<String, dynamic> Function(T value) toJson,
) => switch (section) {
  FeedSectionReady<List<T>>(:final value) => {
    'status': 'ready',
    'items': [for (final item in value) toJson(item)],
  },
  FeedSectionFailed<List<T>>(:final errorCode, :final requestId) => {
    'status': 'failed',
    'error_code': errorCode,
    'request_id': ?requestId,
  },
};

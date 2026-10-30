import 'package:flutter/foundation.dart';
import 'package:on_air/core/time/date_only.dart';

/// An approved review; the reviewer's name is already shortened on the server
/// (research R16).
@immutable
final class ApprovedReview {
  const ApprovedReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdOn,
    required this.reviewerShortName,
  });

  factory ApprovedReview.fromJson(Map<String, dynamic> json) => ApprovedReview(
    id: json['id'] as String,
    rating: json['rating'] as int,
    comment: json['comment'] as String?,
    createdOn: DateOnly.parse(json['created_on'] as String),
    reviewerShortName: json['reviewer_short_name'] as String,
  );

  final String id;
  final int rating;
  final String? comment;
  final DateOnly createdOn;
  final String reviewerShortName;

  @override
  bool operator ==(Object other) =>
      other is ApprovedReview &&
      other.id == id &&
      other.rating == rating &&
      other.comment == comment &&
      other.createdOn == createdOn &&
      other.reviewerShortName == reviewerShortName;

  @override
  int get hashCode =>
      Object.hash(id, rating, comment, createdOn, reviewerShortName);
}

@immutable
final class ReviewsPage {
  const ReviewsPage({required this.items, required this.nextCursor});

  factory ReviewsPage.fromJson(Map<String, dynamic> json) => ReviewsPage(
    items: [
      for (final raw in json['items'] as List? ?? const [])
        ApprovedReview.fromJson(Map<String, dynamic>.from(raw as Map)),
    ],
    nextCursor: json['next_cursor'] as String?,
  );

  final List<ApprovedReview> items;
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      other is ReviewsPage &&
      listEquals(other.items, items) &&
      other.nextCursor == nextCursor;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(items),
    nextCursor,
  );
}

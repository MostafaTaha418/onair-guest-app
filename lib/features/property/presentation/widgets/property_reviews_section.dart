import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/listings/domain/approved_review.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The latest three approved reviews over the reviews gradient, with a link
/// to the full list.
final class PropertyReviewsSection extends StatelessWidget {
  const PropertyReviewsSection({required this.details, super.key});

  final PropertyDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.all(Dimens.space16),
      decoration: BoxDecoration(gradient: colors.gradient('reviews')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.propertyReviews,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: Dimens.space8),
          if (details.latestReviews.isEmpty)
            Text(
              l10n.reviewsNone,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
              ),
            )
          else
            for (final review in details.latestReviews) ...[
              ReviewTile(review: review),
              const SizedBox(height: Dimens.space12),
            ],
          TextButton(
            onPressed: () =>
                context.push(AppRoutes.propertyReviews(details.id)),
            child: Text(l10n.reviewsSeeAll),
          ),
        ],
      ),
    );
  }
}

/// One approved review: stars, comment, short name, and the review date.
/// Reused by the full reviews screen (T074).
final class ReviewTile extends StatelessWidget {
  const ReviewTile({required this.review, super.key});

  final ApprovedReview review;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var star = 1; star <= 5; star++)
              Icon(
                star <= review.rating ? Icons.star_rounded : Icons.star_outline,
                size: 16,
                color: colors['star'],
              ),
          ],
        ),
        if (review.comment != null) ...[
          const SizedBox(height: 4),
          Text(
            review.comment!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          '${review.reviewerShortName} · '
          '${DateOnlyFormatter.dayMonth(review.createdOn)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

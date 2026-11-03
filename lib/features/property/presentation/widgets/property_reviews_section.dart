import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/listings/domain/approved_review.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The latest three approved reviews in a calm summary card, with a link
/// to the full list.
final class PropertyReviewsSection extends StatelessWidget {
  const PropertyReviewsSection({required this.details, super.key});

  final PropertyDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.propertyReviews,
          style: context.textStyles.sectionTitle.copyWith(
            color: colors['textAccent'],
          ),
        ),
        const SizedBox(height: Dimens.space12),
        Container(
          width: double.infinity,
          padding: const EdgeInsetsDirectional.all(Dimens.space16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(Dimens.radiusCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (details.reviewCount > 0) ...[
                Row(
                  children: [
                    Icon(AppIcons.starRounded, color: colors['star'], size: 24),
                    const SizedBox(width: Dimens.space8),
                    Text(
                      details.ratingAvg?.toStringAsFixed(1) ?? '',
                      style: context.textStyles.sectionTitle.copyWith(
                        color: colors.textPrimary,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(width: Dimens.space8),
                    Text(
                      l10n.reviewsCount(details.reviewCount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimens.space16),
              ],
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
                  const SizedBox(height: Dimens.space16),
                ],
            ],
          ),
        ),
        TextButton(
          onPressed: () => context.push(AppRoutes.propertyReviews(details.id)),
          child: Text(l10n.reviewsSeeAll),
        ),
      ],
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
                star <= review.rating
                    ? AppIcons.starRounded
                    : AppIcons.starOutline,
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
          '${DateOnlyFormatter.dayMonth(review.createdOn, locale: AppLocalizations.of(context).localeName)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

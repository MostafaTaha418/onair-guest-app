import 'package:flutter/material.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/design_system/components/rating_badge.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The apartment title, type, area • city, and the rating badge.
final class PropertyTitleSection extends StatelessWidget {
  const PropertyTitleSection({
    required this.details,
    required this.typeLabel,
    super.key,
  });

  final PropertyDetails details;

  /// Resolved from the reference data; falls back to the raw key.
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final isNarrow = MediaQuery.sizeOf(context).width < 360;
    final title = Text(
      details.title,
      style: context.textStyles.sectionTitle.copyWith(
        fontSize: isNarrow ? 18 : 20,
        color: colors.textPrimary,
      ),
    );
    final price = Text(
      l10n.nightlyPrice(MoneyFormatter().format(details.nightlyPrice)),
      textAlign: TextAlign.end,
      style: context.textStyles.price.copyWith(
        color: colors['textAccent'],
        fontSize: isNarrow ? 14 : 16,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isNarrow) ...[
          title,
          const SizedBox(height: Dimens.space4),
          price,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: title),
              const SizedBox(width: Dimens.space8),
              Flexible(flex: 2, child: price),
            ],
          ),
        const SizedBox(height: Dimens.space8),
        Row(
          children: [
            Icon(AppIcons.location, size: 16, color: colors['textAccent']),
            const SizedBox(width: Dimens.space4),
            Expanded(
              child: Text(
                '$typeLabel • ${details.areaName} • ${details.cityName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        if (details.reviewCount > 0) ...[
          const SizedBox(height: Dimens.space8),
          Row(
            children: [
              RatingBadge(
                ratingText: details.ratingAvg?.toStringAsFixed(1) ?? '',
                semanticsLabel: l10n.ratingSemantics(
                  details.ratingAvg?.toStringAsFixed(1) ?? '',
                  details.reviewCount,
                ),
              ),
              const SizedBox(width: Dimens.space4),
              Text(
                l10n.reviewsCount(details.reviewCount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

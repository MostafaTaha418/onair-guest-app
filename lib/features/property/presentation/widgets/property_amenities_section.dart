import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Cupertino or Lucide icon per amenity key; unknown names use a check mark
/// (data-model "ReferenceData").
const _amenityIcons = <String, IconData>{
  'wifi': AppIcons.wifi,
  'ac': AppIcons.acUnit,
  'kitchen': AppIcons.kitchen,
  'washer': AppIcons.localLaundryService,
  'parking': AppIcons.localParking,
  'pool': AppIcons.pool,
  'elevator': AppIcons.elevator,
  'tv': AppIcons.tv,
  'balcony': AppIcons.balcony,
  'sea_view': AppIcons.waves,
};

IconData amenityIcon(String? name) =>
    _amenityIcons[name] ?? AppIcons.checkCircleOutline;

/// The first six amenities with a "see all" sheet for the rest.
final class PropertyAmenitiesSection extends StatelessWidget {
  const PropertyAmenitiesSection({required this.details, super.key});

  final PropertyDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final preview = details.amenities.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.propertyAmenities,
          style: context.textStyles.sectionTitle.copyWith(
            color: colors['textAccent'],
          ),
        ),
        const SizedBox(height: Dimens.space12),
        if (preview.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 540 ? 3 : 2;
              final width =
                  (constraints.maxWidth - (columns - 1) * Dimens.space8) /
                  columns;
              return Wrap(
                spacing: Dimens.space8,
                runSpacing: Dimens.space8,
                children: [
                  for (final amenity in preview)
                    Container(
                      width: width,
                      constraints: const BoxConstraints(minHeight: 72),
                      padding: const EdgeInsetsDirectional.all(Dimens.space12),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(Dimens.radiusCard),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            amenityIcon(amenity.icon),
                            size: 22,
                            color: colors['textAccent'],
                          ),
                          const SizedBox(width: Dimens.space8),
                          Expanded(
                            child: Text(
                              amenity.label,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        if (details.amenities.length > 6)
          TextButton(
            onPressed: () => _showAllAmenities(context),
            child: Text(l10n.propertySeeAllAmenities),
          ),
      ],
    );
  }

  void _showAllAmenities(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Dimens.radiusSheet),
          ),
        ),
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsetsDirectional.all(Dimens.space16),
            children: [
              Text(
                l10n.propertyAmenities,
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: Dimens.space8),
              for (final amenity in details.amenities)
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    vertical: Dimens.space8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        amenityIcon(amenity.icon),
                        size: 20,
                        color: colors.textPrimary,
                      ),
                      const SizedBox(width: Dimens.space12),
                      Text(
                        amenity.label,
                        style: Theme.of(sheetContext).textTheme.bodyMedium
                            ?.copyWith(color: colors.textPrimary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

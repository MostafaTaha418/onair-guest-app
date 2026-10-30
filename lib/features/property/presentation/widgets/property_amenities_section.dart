import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Material icon per amenity key; unknown names fall back to a generic icon
/// (data-model "ReferenceData").
const _amenityIcons = <String, IconData>{
  'wifi': Icons.wifi,
  'ac': Icons.ac_unit,
  'kitchen': Icons.kitchen,
  'washer': Icons.local_laundry_service,
  'parking': Icons.local_parking,
  'pool': Icons.pool,
  'elevator': Icons.elevator,
  'tv': Icons.tv,
  'balcony': Icons.balcony,
  'sea_view': Icons.waves,
};

IconData amenityIcon(String? name) =>
    _amenityIcons[name] ?? Icons.check_circle_outline;

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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: Dimens.space8),
        if (preview.isNotEmpty)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Dimens.space8,
            crossAxisSpacing: Dimens.space8,
            childAspectRatio: 5,
            children: [
              for (final amenity in preview)
                Row(
                  children: [
                    Icon(
                      amenityIcon(amenity.icon),
                      size: 20,
                      color: colors.textPrimary,
                    ),
                    const SizedBox(width: Dimens.space8),
                    Flexible(
                      child: Text(
                        amenity.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
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

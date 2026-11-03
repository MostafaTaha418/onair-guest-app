import 'package:flutter/material.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Bedrooms, bathrooms, max guests, and area — one compact row of facts.
final class PropertySpecsRow extends StatelessWidget {
  const PropertySpecsRow({required this.details, super.key});

  final PropertyDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final facts = [
      (
        AppIcons.bedOutlined,
        l10n.propertyBedrooms(details.bedrooms),
      ),
      (
        AppIcons.bathtubOutlined,
        l10n.propertyBathrooms(details.bathrooms),
      ),
      (
        AppIcons.peopleOutline,
        l10n.propertyMaxGuests(details.maxGuests),
      ),
      if (details.areaSqm != null)
        (AppIcons.squareFootOutlined, l10n.propertyArea(details.areaSqm!)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 540 ? 4 : 2;
        final width =
            (constraints.maxWidth - (columns - 1) * Dimens.space8) / columns;
        return Wrap(
          spacing: Dimens.space8,
          runSpacing: Dimens.space8,
          children: [
            for (final (icon, label) in facts)
              Container(
                width: width,
                constraints: const BoxConstraints(minHeight: 76),
                padding: const EdgeInsetsDirectional.all(Dimens.space12),
                decoration: BoxDecoration(
                  color: colors['detailCard'],
                  borderRadius: BorderRadius.circular(Dimens.radiusCard),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 22, color: colors['textAccent']),
                    const SizedBox(height: Dimens.space8),
                    Text(
                      label,
                      style: context.textStyles.propertySpec.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

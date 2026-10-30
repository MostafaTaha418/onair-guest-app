import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
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
        Icons.bed_outlined,
        l10n.propertyBedrooms(details.bedrooms),
      ),
      (
        Icons.bathtub_outlined,
        l10n.propertyBathrooms(details.bathrooms),
      ),
      (
        Icons.people_outline,
        l10n.propertyMaxGuests(details.maxGuests),
      ),
      if (details.areaSqm != null)
        (Icons.square_foot_outlined, l10n.propertyArea(details.areaSqm!)),
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final (icon, label) in facts)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The public location: governorate، city، area, plus the approved address
/// text when the server provides it (D-001). Text only — no map, no
/// coordinates anywhere.
final class PropertyAddressSection extends StatelessWidget {
  const PropertyAddressSection({required this.details, super.key});

  final PropertyDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.propertyLocation,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${details.governorateName}، ${details.cityName}، ${details.areaName}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
          ),
        ),
        if (details.addressText != null) ...[
          const SizedBox(height: 4),
          Text(
            details.addressText!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

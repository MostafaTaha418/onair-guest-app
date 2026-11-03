import 'package:flutter/material.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.location, color: colors['textAccent']),
              const SizedBox(width: Dimens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        details.governorateName,
                        details.cityName,
                        details.areaName,
                      ].join(l10n.localeName == 'ar' ? '، ' : ', '),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (details.addressText != null) ...[
                      const SizedBox(height: Dimens.space4),
                      Text(
                        details.addressText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

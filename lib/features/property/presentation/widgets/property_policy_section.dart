import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/features/property/domain/policy_text.dart';
import 'package:on_air/features/property/presentation/widgets/policy_line_text.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The deposit and cancellation sentences, one bullet per line — no amounts
/// are computed on the device (data-model "PolicySummary").
final class PropertyPolicySection extends StatelessWidget {
  const PropertyPolicySection({required this.details, super.key});

  final PropertyDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.propertyPolicy,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        for (final line in policyLines(details.policy))
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 8),
                  child: Icon(
                    Icons.circle,
                    size: 5,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    policyLineText(line, l10n),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:on_air/design_system/components/expandable_text.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Check-in/out times, the visitors rule, and the owner's house rules —
/// plain text only, never rendered as links or HTML.
final class PropertyRulesSection extends StatelessWidget {
  const PropertyRulesSection({required this.details, super.key});

  final PropertyDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final rules = details.rules;
    final visitors = rules.visitorsAllowed
        ? (rules.maxVisitors == null
              ? l10n.rulesVisitorsAllowedNoLimit
              : l10n.rulesVisitorsAllowed(rules.maxVisitors!))
        : l10n.rulesVisitorsNotAllowed;
    final lines = [
      l10n.rulesCheckIn(rules.checkInTime),
      l10n.rulesCheckOut(rules.checkOutTime),
      visitors,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.propertyRules,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        for (final line in lines)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 18, color: colors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (rules.houseRules != null)
          ExpandableText(
            text: rules.houseRules!,
            moreLabel: l10n.showMore,
            lessLabel: l10n.showLess,
          ),
      ],
    );
  }
}

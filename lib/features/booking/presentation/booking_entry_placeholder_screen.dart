import 'package:flutter/material.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// G2 entry point until booking ships: it echoes the carried terms, dates,
/// and guests without ever showing the raw terms value (research R10).
final class BookingEntryPlaceholderScreen extends StatelessWidget {
  const BookingEntryPlaceholderScreen({
    required this.propertyId,
    required this.query,
    super.key,
  });

  final String propertyId;
  final Map<String, String> query;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final checkIn = DateOnly.tryParse(query['checkIn']);
    final checkOut = DateOnly.tryParse(query['checkOut']);
    final guests = int.tryParse(query['guests'] ?? '');
    final hasTerms = query.containsKey('terms');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookingEntryTitle)),
      body: Padding(
        padding: const EdgeInsetsDirectional.all(Dimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bookingEntryComingSoon,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: Dimens.space16),
            if (checkIn != null && checkOut != null)
              Text(
                '${l10n.searchDatesLabel}: '
                '${DateOnlyFormatter.dayMonth(checkIn)} – '
                '${DateOnlyFormatter.dayMonth(checkOut)}',
              ),
            if (guests != null) Text('${l10n.searchGuestsLabel}: $guests'),
            if (hasTerms) Text(l10n.bookingEntryTermsCarried),
          ],
        ),
      ),
    );
  }
}

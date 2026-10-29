import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The signed-in guest's next booking. Named a tile to stay distinct from
/// the `UpcomingBookingCard` model it renders; the booking route itself is
/// a G2 placeholder.
final class UpcomingBookingTile extends StatelessWidget {
  const UpcomingBookingTile({required this.booking, super.key});

  final UpcomingBookingCard booking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return InkWell(
      onTap: () => context.push('/bookings/${booking.bookingId}'),
      borderRadius: BorderRadius.circular(Dimens.radiusCard),
      child: Container(
        padding: const EdgeInsetsDirectional.all(Dimens.space16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(Dimens.radiusCard),
          border: Border.all(color: colors['subtleBorder']),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.propertyTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: Dimens.space4),
            Text(
              '${DateOnlyFormatter.dayMonth(booking.checkIn)} – '
              '${DateOnlyFormatter.dayMonth(booking.checkOut)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: Dimens.space8),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: Dimens.space8,
                vertical: Dimens.space4,
              ),
              decoration: BoxDecoration(
                color: colors['successContainer'],
                borderRadius: BorderRadius.circular(Dimens.radiusChip),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: colors['onSuccessContainer'],
                  ),
                  const SizedBox(width: Dimens.space4),
                  Text(
                    l10n.homeUpcomingConfirmed,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors['onSuccessContainer'],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

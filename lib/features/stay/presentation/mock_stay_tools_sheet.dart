import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/bookings/presentation/booking_details_cubit.dart';
import 'package:on_air/features/stay/data/mock_stay_server.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The mock-mode owner tools (Appendix D §8): each tile plays the owner or
/// collector side against the given booking, then refreshes the details.
Future<void> showMockStayTools(BuildContext context, String bookingId) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadiusDirectional.vertical(
        top: Radius.circular(Dimens.radiusSheet),
      ),
    ),
    backgroundColor: context.colors.surface,
    builder: (sheetContext) {
      // The sheet route has its own context: capture the real providers
      // from the screen before opening.
      final stay = context.read<MockStayServer?>();
      final details = context.read<BookingDetailsCubit>();
      final tiles = <(String, Future<void> Function())>[
        (l10n.mockOwnerHandover, () => stay!.ownerConfirmsHandover(bookingId)),
        (l10n.mockOwnerCheckout, () => stay!.ownerConfirmsCheckout(bookingId)),
        (
          l10n.mockOwnerCheckoutKey,
          () => stay!.ownerConfirmsCheckout(bookingId, keyLeftSafe: true),
        ),
        (l10n.mockCollectorCash, () => stay!.collectorRecordsCash(bookingId)),
        (l10n.mockOpenClaim, () => stay!.openClaim(bookingId)),
        (l10n.mockAdvanceRefund, () => stay!.advanceRefund(bookingId)),
        (
          l10n.mockChangeTerms,
          () async => stay!.forceTermsChangeOnce(bookingId),
        ),
      ];
      return SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            Dimens.screenSide,
            Dimens.space8,
            Dimens.screenSide,
            Dimens.space16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: SizedBox(
                  width: 40,
                  height: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.colors.border,
                      borderRadius: BorderRadius.circular(Dimens.radiusChip),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Dimens.space16),
              Semantics(
                header: true,
                child: Text(
                  l10n.mockToolsTitle,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: Dimens.space8),
              for (final (label, action) in tiles)
                ListTile(
                  title: Text(label),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await action();
                    await details.refresh();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

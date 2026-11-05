import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/design_system/components/on_air_confirm_sheet.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/stay/domain/stay_repository.dart';
import 'package:on_air/features/stay/presentation/stay_ack/stay_ack_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// «استلمت الشقة» — a plain confirmation, no code and no photos (US3).
Future<bool> showCheckInSheet(
  BuildContext context,
  BookingDetails details,
) => _showAckSheet(context, details, checkIn: true);

/// «غادرت الشقة» — the same sheet with the check-out wording.
Future<bool> showCheckOutSheet(
  BuildContext context,
  BookingDetails details,
) => _showAckSheet(context, details, checkIn: false);

Future<bool> _showAckSheet(
  BuildContext context,
  BookingDetails details, {
  required bool checkIn,
}) async {
  // Read the providers from the outer context before the sheet route opens.
  final stay = context.read<StayRepository>();
  final logger = context.read<AppLogger>();
  return await OnAirConfirmSheet.show<bool>(
        context,
        builder: (_) => BlocProvider<StayAckCubit>(
          create: (_) =>
              StayAckCubit(stay: stay, logger: logger, bookingId: details.id),
          child: _AckSheetBody(checkIn: checkIn, bookingId: details.id),
        ),
      ) ??
      false;
}

final class _AckSheetBody extends StatelessWidget {
  const _AckSheetBody({required this.checkIn, required this.bookingId});

  final bool checkIn;
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<StayAckCubit, StayAckState>(
      listener: (context, state) {
        if (state is AckDone) Navigator.pop(context, true);
      },
      builder: (context, state) {
        final failed = state is AckFailed ? state : null;
        return OnAirConfirmSheet(
          title: checkIn ? l10n.checkinSheetTitle : l10n.checkoutSheetTitle,
          body: checkIn ? l10n.checkinSheetBody : l10n.checkoutSheetBody,
          confirmLabel: checkIn
              ? l10n.checkinSheetConfirm
              : l10n.checkoutSheetConfirm,
          cancelLabel: l10n.sheetNotYet,
          isLoading: state is AckSubmitting,
          errorText: failed == null
              ? null
              : apiErrorMessage(failed.error, l10n),
          onConfirm: checkIn
              ? () => context.read<StayAckCubit>().confirmCheckIn()
              : () => context.read<StayAckCubit>().confirmCheckOut(),
          // Only the check-in sheet carries the support escape hatch.
          extraActionLabel: checkIn ? l10n.checkinProblem : null,
          onExtraAction: checkIn
              ? () {
                  final router = GoRouter.of(context);
                  Navigator.pop(context, false);
                  unawaited(
                    router.push('${AppRoutes.supportNew}?booking=$bookingId'),
                  );
                }
              : null,
        );
      },
    );
  }
}

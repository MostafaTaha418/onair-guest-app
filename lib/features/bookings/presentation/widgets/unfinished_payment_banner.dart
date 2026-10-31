import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/design_system/components/info_banner.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/bookings/presentation/unfinished_payment_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The unfinished-payment banner (US6): shown on Home and My Bookings while
/// a payment is still pending on the server; opens the attempt's status.
/// Harnesses that pump the screens without the app-scoped cubit show nothing.
final class UnfinishedPaymentBanner extends StatelessWidget {
  const UnfinishedPaymentBanner({super.key});

  UnfinishedPaymentCubit? _cubit(BuildContext context) {
    try {
      return context.read<UnfinishedPaymentCubit>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit(context);
    if (cubit == null) return const SizedBox.shrink();
    return BlocBuilder<UnfinishedPaymentCubit, UnfinishedPaymentState>(
      builder: (context, state) {
        if (state is! UnfinishedSome) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context);
        final booking = state.booking;
        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            Dimens.screenSide,
            Dimens.space8,
            Dimens.screenSide,
            0,
          ),
          child: InfoBanner(
            tone: StatusTone.warning,
            message: l10n.unfinishedPaymentBanner,
            actionLabel: l10n.unfinishedPaymentOpen,
            onAction: () async {
              final target = await cubit.targetFor(booking);
              if (context.mounted) unawaited(context.push(target));
            },
          ),
        );
      },
    );
  }
}

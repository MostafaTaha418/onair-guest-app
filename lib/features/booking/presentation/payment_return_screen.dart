import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/countdown.dart';
import 'package:on_air/design_system/components/countdown_text.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/app_update/presentation/not_available_screen.dart';
import 'package:on_air/features/booking/domain/verification_outcome.dart';
import 'package:on_air/features/booking/presentation/payment_attempt_cubit.dart';
import 'package:on_air/features/booking/presentation/payment_verification_cubit.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/notifications/presentation/push_permission_coordinator.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The screen the app lands on after the Kashier page: it waits for the
/// server (stream + polling) and shows one of four outcomes (data-model
/// §6). Link query parameters other than `booking` are ignored.
final class PaymentReturnScreen extends StatelessWidget {
  const PaymentReturnScreen({required this.bookingIdFromLink, super.key});

  final String? bookingIdFromLink;

  @override
  Widget build(BuildContext context) {
    final attemptState = context.read<PaymentAttemptCubit>().state;
    final fromAttempt = attemptState is AttemptOpened
        ? attemptState.attempt.bookingId
        : null;
    final bookingId = AppRoutes.isUuidV4(bookingIdFromLink ?? '')
        ? bookingIdFromLink
        : fromAttempt;
    if (bookingId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(AppRoutes.bookingsTab('current'));
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    return BlocProvider<PaymentVerificationCubit>(
      key: ValueKey(bookingId),
      create: (context) => PaymentVerificationCubit(
        bookings: context.read(),
        signals: context.read(),
        bookingId: bookingId,
        logger: context.read<AppLogger>(),
      )..start(),
      child: const _ReturnBody(),
    );
  }
}

final class _ReturnBody extends StatefulWidget {
  const _ReturnBody();

  @override
  State<_ReturnBody> createState() => _ReturnBodyState();
}

final class _ReturnBodyState extends State<_ReturnBody> {
  Countdown? _countdown;
  var _asked = false;

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentVerifying)),
      body: BlocConsumer<PaymentVerificationCubit, VerifyState>(
        listener: (context, state) {
          if (state is VerifyResolved &&
              state.outcome == VerificationOutcome.success &&
              !_asked) {
            _asked = true;
            // US5: the push sheet shows once, after the first successful
            // payment. Tests without a coordinator skip the ask.
            try {
              final coordinator = context.read<PushPermissionCoordinator>();
              unawaited(coordinator.maybeAskAfterFirstSuccess(context));
            } on ProviderNotFoundException {
              // No coordinator in this harness: nothing to ask.
            }
          }
        },
        builder: (context, state) => switch (state) {
          VerifyWaiting() => _Waiting(l10n: l10n),
          VerifyResolved(:final outcome, :final details) => switch (outcome) {
            VerificationOutcome.success => _Success(
              l10n: l10n,
              details: details,
              onCountdown: (countdown) => _countdown = countdown,
            ),
            VerificationOutcome.failed => _Failed(l10n: l10n, details: details),
            VerificationOutcome.conflict => _Conflict(
              l10n: l10n,
              details: details,
            ),
            VerificationOutcome.waiting => _Waiting(l10n: l10n),
          },
          VerifyTimeout() => _Timeout(l10n: l10n),
          VerifyNotAvailable() => const NotAvailableScreen(),
        },
      ),
    );
  }
}

final class _Waiting extends StatelessWidget {
  const _Waiting({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: l10n.paymentVerifying,
          child: const CircularProgressIndicator(),
        ),
        const SizedBox(height: Dimens.space16),
        Text(l10n.paymentVerifying, textAlign: TextAlign.center),
        const SizedBox(height: Dimens.space8),
        Text(
          l10n.paymentVerifyingBody,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

final class _Success extends StatelessWidget {
  const _Success({
    required this.l10n,
    required this.details,
    required this.onCountdown,
  });

  final AppLocalizations l10n;
  final BookingDetails details;
  final ValueChanged<Countdown?> onCountdown;

  @override
  Widget build(BuildContext context) {
    final attemptCubit = context.read<PaymentAttemptCubit>();
    final deadline = details.ownerResponseDeadline;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(Dimens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 64),
            const SizedBox(height: Dimens.space16),
            Text(l10n.paymentSuccessTitle, textAlign: TextAlign.center),
            const SizedBox(height: Dimens.space8),
            Text(l10n.paymentSuccessBody, textAlign: TextAlign.center),
            if (deadline != null) ...[
              const SizedBox(height: Dimens.space12),
              _DeadlineCountdown(
                deadlineUtc: deadline,
                onCountdown: onCountdown,
              ),
            ],
            const SizedBox(height: Dimens.space24),
            OnAirPrimaryButton(
              key: const ValueKey('return-view-booking'),
              label: l10n.paymentViewBooking,
              onPressed: () async {
                await attemptCubit.finish();
                if (context.mounted) {
                  context.go(AppRoutes.bookingDetails(details.id));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

final class _DeadlineCountdown extends StatefulWidget {
  const _DeadlineCountdown({
    required this.deadlineUtc,
    required this.onCountdown,
  });

  final DateTime deadlineUtc;
  final ValueChanged<Countdown?> onCountdown;

  @override
  State<_DeadlineCountdown> createState() => _DeadlineCountdownState();
}

final class _DeadlineCountdownState extends State<_DeadlineCountdown> {
  late final Countdown _countdown = Countdown(
    deadlineUtc: widget.deadlineUtc,
  );

  @override
  void initState() {
    super.initState();
    widget.onCountdown(_countdown);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CountdownText(
      remaining: _countdown.remaining,
      format: (d) => l10n.ownerDeadlineCountdown(Countdown.format(d)),
    );
  }
}

final class _Failed extends StatelessWidget {
  const _Failed({required this.l10n, required this.details});

  final AppLocalizations l10n;
  final BookingDetails details;

  @override
  Widget build(BuildContext context) {
    final attemptCubit = context.read<PaymentAttemptCubit>();
    final attemptState = attemptCubit.state;
    // Read the terms before the reset: the new attempt keeps them.
    final termsHash = switch (attemptState) {
      AttemptOpened(:final attempt) => attempt.termsHash,
      AttemptFailed(:final attempt) => attempt?.termsHash ?? '',
      _ => '',
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(Dimens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: Dimens.space16),
            Text(l10n.paymentFailedTitle, textAlign: TextAlign.center),
            const SizedBox(height: Dimens.space8),
            Text(l10n.paymentFailedBody, textAlign: TextAlign.center),
            const SizedBox(height: Dimens.space24),
            OnAirPrimaryButton(
              key: const ValueKey('return-try-again'),
              label: l10n.paymentTryAgain,
              onPressed: () async {
                await attemptCubit.newAttempt();
                if (!context.mounted) return;
                if (termsHash.isEmpty) {
                  context.go(AppRoutes.property(details.property.id));
                  return;
                }
                final checkIn = details.stay.checkIn;
                final checkOut = details.stay.checkOut;
                context.go(
                  '/book/${details.property.id}/dates'
                  '?checkIn=$checkIn&checkOut=$checkOut'
                  '&guests=${details.guests}'
                  '&terms=${Uri.encodeQueryComponent(termsHash)}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

final class _Conflict extends StatelessWidget {
  const _Conflict({required this.l10n, required this.details});

  final AppLocalizations l10n;
  final BookingDetails details;

  @override
  Widget build(BuildContext context) {
    final attemptCubit = context.read<PaymentAttemptCubit>();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(Dimens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy, size: 64),
            const SizedBox(height: Dimens.space16),
            Text(l10n.paymentConflictTitle, textAlign: TextAlign.center),
            const SizedBox(height: Dimens.space8),
            Text(
              l10n.paymentConflictBody(MoneyFormatter().format(details.paid)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimens.space24),
            OnAirPrimaryButton(
              key: const ValueKey('return-find-dates'),
              label: l10n.paymentFindOtherDates,
              onPressed: () async {
                await attemptCubit.finish();
                if (context.mounted) {
                  context.go(AppRoutes.property(details.property.id));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

final class _Timeout extends StatelessWidget {
  const _Timeout({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(Dimens.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 64),
          const SizedBox(height: Dimens.space16),
          Text(l10n.paymentTimeoutTitle, textAlign: TextAlign.center),
          const SizedBox(height: Dimens.space8),
          Text(l10n.paymentTimeoutBody, textAlign: TextAlign.center),
          const SizedBox(height: Dimens.space24),
          // The attempt record stays: the booking may still confirm.
          OnAirPrimaryButton(
            key: const ValueKey('return-go-bookings'),
            label: l10n.paymentGoToBookings,
            onPressed: () => context.go(AppRoutes.bookingsTab('current')),
          ),
        ],
      ),
    ),
  );
}

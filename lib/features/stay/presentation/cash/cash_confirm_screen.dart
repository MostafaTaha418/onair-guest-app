import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/countdown.dart';
import 'package:on_air/design_system/components/amount_row.dart';
import 'package:on_air/design_system/components/bottom_action_bar.dart';
import 'package:on_air/design_system/components/countdown_text.dart';
import 'package:on_air/design_system/components/info_banner.dart';
import 'package:on_air/design_system/components/notice_card.dart';
import 'package:on_air/design_system/components/on_air_otp_field.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/on_air_text_field.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/bookings/domain/booking_stay_parts.dart';
import 'package:on_air/features/stay/presentation/cash/cash_confirm_cubit.dart';
import 'package:on_air/features/stay/presentation/cash/cash_texts.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class CashConfirmScreen extends StatefulWidget {
  const CashConfirmScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  State<CashConfirmScreen> createState() => _CashConfirmScreenState();
}

final class _CashConfirmScreenState extends State<CashConfirmScreen> {
  final TextEditingController _phone = TextEditingController();
  String _code = '';
  bool _agreed = false;
  Countdown? _resendCountdown;
  StreamSubscription<Duration>? _resendSubscription;
  DateTime? _resendDeadline;

  @override
  void dispose() {
    _phone.dispose();
    unawaited(_resendSubscription?.cancel());
    _resendCountdown?.cancel();
    // The emailed code never outlives the screen.
    _code = '';
    super.dispose();
  }

  void _syncResendCountdown(DateTime? resendAvailableAt) {
    if (resendAvailableAt == null) {
      _resendDeadline = null;
      unawaited(_resendSubscription?.cancel());
      _resendCountdown?.cancel();
      _resendCountdown = null;
      return;
    }
    if (resendAvailableAt == _resendDeadline) return;
    _resendDeadline = resendAvailableAt;
    unawaited(_resendSubscription?.cancel());
    _resendCountdown?.cancel();
    final countdown = Countdown(deadlineUtc: resendAvailableAt);
    _resendCountdown = countdown;
    _resendSubscription = countdown.remaining.listen((remaining) {
      if (remaining == Duration.zero && mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<CashConfirmCubit, CashConfirmState>(
      listener: (context, state) {
        if (state is CashDone) {
          context.pushReplacement(
            AppRoutes.receipt(widget.bookingId, state.paymentId),
          );
        } else if (state is CashNotAllowed) {
          context.go(AppRoutes.bookingDetails(widget.bookingId));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.stayStepNotAvailable)),
          );
        }
        if (state is CashCodeEntry) {
          _syncResendCountdown(state.resendAvailableAt);
        }
      },
      builder: (context, state) {
        if (state is CashCodeEntry) {
          _syncResendCountdown(state.resendAvailableAt);
        }
        return Scaffold(
          appBar: AppBar(title: Text(l10n.cashTitle)),
          bottomNavigationBar: switch (state) {
            CashPhoneEntry _ ||
            CashStarting _ ||
            CashNotAuthorized _ => _phoneBar(context, state, l10n),
            CashCodeEntry _ || CashConfirming _ => _codeBar(context, l10n),
            _ => null,
          },
          body: switch (state) {
            CashPhoneEntry() => _PhoneStep(
              state: state,
              controller: _phone,
              bookingId: widget.bookingId,
            ),
            CashStarting() => _PhoneStep(
              state: CashPhoneEntry(amount: state.amount),
              controller: _phone,
              bookingId: widget.bookingId,
            ),
            CashNotAuthorized() => _PhoneStep(
              state: CashPhoneEntry(amount: state.amount),
              controller: _phone,
              bookingId: widget.bookingId,
              notAuthorized: true,
            ),
            CashCodeEntry() => _CodeStep(
              request: state.request,
              error: state.error,
              waitingToResend: _waitingToResend,
              resendStream: _resendCountdown?.remaining,
              agreed: _agreed,
              onAgreedChanged: (value) => setState(() => _agreed = value),
              onCodeChanged: (value) => setState(() => _code = value),
            ),
            CashConfirming() => _CodeStep(
              request: state.request,
              error: null,
              waitingToResend: false,
              resendStream: _resendCountdown?.remaining,
              agreed: _agreed,
              onAgreedChanged: (value) => setState(() => _agreed = value),
              onCodeChanged: (value) => setState(() => _code = value),
            ),
            CashFailed() => ErrorView(
              message: apiErrorMessage(state.error, l10n),
              onRetry: context.read<CashConfirmCubit>().load,
              referenceNumber: state.error.requestId,
            ),
            CashOffline() => ErrorView(
              message: l10n.stayNeedsConnection,
              onRetry: context.read<CashConfirmCubit>().load,
            ),
            CashNotAvailable() => EmptyView(
              icon: AppIcons.infoOutline,
              message: l10n.notAvailable,
            ),
            _ => const _CashSkeleton(),
          },
        );
      },
    );
  }

  bool get _waitingToResend =>
      _resendDeadline != null &&
      DateTime.now().toUtc().isBefore(_resendDeadline!);

  Widget _phoneBar(
    BuildContext context,
    CashConfirmState state,
    AppLocalizations l10n,
  ) => BottomActionBar(
    leading: const SizedBox.shrink(),
    action: OnAirPrimaryButton(
      key: const ValueKey('cash-send'),
      label: l10n.cashSendCode,
      isLoading: state is CashStarting,
      onPressed: () =>
          context.read<CashConfirmCubit>().submitPhone(_phone.text),
    ),
  );

  Widget _codeBar(BuildContext context, AppLocalizations l10n) {
    final confirming =
        context.watch<CashConfirmCubit>().state is CashConfirming;
    return BottomActionBar(
      leading: const SizedBox.shrink(),
      action: OnAirPrimaryButton(
        key: const ValueKey('cash-confirm'),
        label: l10n.cashConfirmButton,
        isLoading: confirming,
        onPressed: _code.length == 6 && _agreed && !confirming
            ? () => context.read<CashConfirmCubit>().confirm(_code)
            : null,
      ),
    );
  }
}

final class _PhoneStep extends StatelessWidget {
  const _PhoneStep({
    required this.state,
    required this.controller,
    required this.bookingId,
    this.notAuthorized = false,
  });

  final CashPhoneEntry state;
  final TextEditingController controller;
  final String bookingId;
  final bool notAuthorized;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final amount = MoneyFormatter().format(state.amount);
    return ListView(
      padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  label: l10n.cashAmountLocked,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(Dimens.space16),
                      child: Row(
                        children: [
                          Icon(
                            AppIcons.lockOutlineRounded,
                            size: 20,
                            color: context.colors.textSecondary,
                          ),
                          const SizedBox(width: Dimens.space8),
                          Expanded(
                            child: AmountRow(
                              label: l10n.cashAmountLabel,
                              value: amount,
                              emphasized: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Dimens.space16),
                OnAirTextField(
                  controller: controller,
                  label: l10n.cashPhoneLabel,
                  hint: l10n.cashPhoneHint,
                  keyboardType: TextInputType.phone,
                  errorText: state.phoneError ? l10n.cashPhoneInvalid : null,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.telephoneNumber],
                ),
                const SizedBox(height: Dimens.space16),
                InfoBanner(
                  message: l10n.cashWarning,
                  tone: StatusTone.warning,
                  icon: AppIcons.warningOutline,
                ),
                if (state.error != null) ...[
                  const SizedBox(height: Dimens.space16),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      apiErrorMessage(state.error!, l10n),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.errorText,
                      ),
                    ),
                  ),
                ],
                if (notAuthorized) ...[
                  const SizedBox(height: Dimens.space16),
                  InfoBanner(
                    message: l10n.stayCollectorNotAuthorized,
                    tone: StatusTone.warning,
                  ),
                  const SizedBox(height: Dimens.space16),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, Dimens.minTouchTarget),
                    ),
                    onPressed: () => context.push(
                      '${AppRoutes.supportNew}?booking=$bookingId',
                    ),
                    child: Text(l10n.cashContactSupport),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _CodeStep extends StatelessWidget {
  const _CodeStep({
    required this.request,
    required this.error,
    required this.waitingToResend,
    required this.resendStream,
    required this.agreed,
    required this.onAgreedChanged,
    required this.onCodeChanged,
  });

  final CashRequest request;
  final ApiError? error;
  final bool waitingToResend;
  final Stream<Duration>? resendStream;
  final bool agreed;
  final ValueChanged<bool> onAgreedChanged;
  final ValueChanged<String> onCodeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NoticeCard(
                  icon: AppIcons.mailOutlineRounded,
                  message: l10n.cashCodeSent(request.maskedEmail),
                ),
                const SizedBox(height: Dimens.space16),
                Card(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(Dimens.space16),
                    child: Column(
                      children: [
                        AmountRow(
                          label: l10n.cashAmountLabel,
                          value: MoneyFormatter().format(request.amount),
                        ),
                        AmountRow(
                          label: l10n.cashCollectorLabel,
                          value: request.collectorDisplayName,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Dimens.space16),
                OnAirOtpField(onCompleted: (_) {}, onChanged: onCodeChanged),
                if (error != null) ...[
                  const SizedBox(height: Dimens.space16),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      apiErrorMessage(error!, l10n),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.errorText,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: Dimens.space8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(64, Dimens.minTouchTarget),
                    ),
                    onPressed: waitingToResend
                        ? null
                        : () => context.read<CashConfirmCubit>().resend(),
                    child: waitingToResend && resendStream != null
                        ? CountdownText(
                            remaining: resendStream!,
                            format: (d) => l10n.cashResendIn(formatWait(d)),
                          )
                        : Text(l10n.cashResend),
                  ),
                ),
                CheckboxListTile(
                  value: agreed,
                  onChanged: (value) => onAgreedChanged(value ?? false),
                  title: Text(
                    l10n.cashStatement(
                      MoneyFormatter().format(request.amount),
                      request.collectorDisplayName,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _CashSkeleton extends StatelessWidget {
  const _CashSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsetsDirectional.all(Dimens.screenSide),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(height: 72),
        SizedBox(height: Dimens.space16),
        SkeletonBox(height: 56),
        SizedBox(height: Dimens.space16),
        SkeletonBox(height: 72),
      ],
    ),
  );
}

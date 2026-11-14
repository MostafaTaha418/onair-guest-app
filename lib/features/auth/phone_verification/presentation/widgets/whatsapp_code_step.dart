import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/design_system/components/notice_card.dart';
import 'package:on_air/design_system/components/on_air_otp_field.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/features/auth/phone_verification/presentation/phone_verification_cubit.dart';
import 'package:on_air/features/auth/phone_verification/presentation/widgets/pv_error_text.dart';
import 'package:on_air/features/auth/phone_verification/presentation/widgets/send_window_notice.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// The WhatsApp code step (contracts/ui-screens.md §4.2): the masked target,
/// the 6-digit field, «افتح واتساب», «تعديل الرقم» and the delivery notices.
/// The resend wait renders from the server window (R8): a `Stream<Duration>`
/// ticking every second rebuilds the text alone.
/// `OTP_SEND_BLOCKED` renders the step with its send controls disabled —
/// the [BlockedNotice] itself lives above, on the screen (T064).
final class WhatsAppCodeStep extends StatefulWidget {
  const WhatsAppCodeStep({
    required this.supportPhone,
    super.key,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// From `app_config`; the «كلّم الدعم» notices dial it (G4 brings the
  /// support screens).
  final String supportPhone;

  /// The device clock the countdown ticks with — injectable so goldens pin
  /// one instant instead of racing the real second hand.
  final DateTime Function() _clock;

  @override
  State<WhatsAppCodeStep> createState() => _WhatsAppCodeStepState();
}

class _WhatsAppCodeStepState extends State<WhatsAppCodeStep> {
  final _codeController = TextEditingController();

  /// The per-second remaining time of the latest window; rebuilt when the
  /// window's `next_send_at` / `blocked_until` change (T063).
  StreamController<Duration>? _countdown;
  Timer? _ticker;
  SendWindow? _countedWindow;

  void _retune(SendWindow window) {
    final counted = _countedWindow;
    if (counted != null &&
        window.nextSendAt == counted.nextSendAt &&
        window.blockedUntil == counted.blockedUntil) {
      return;
    }
    _countedWindow = window;
    _ticker?.cancel();
    unawaited(_countdown?.close());
    final controller = StreamController<Duration>.broadcast();
    // The window freezes its server↔device offset at arrival, so
    // remainingUntilSend already subtracts the elapsed time (R8, review
    // fix 10) — the tick just asks the window again.
    void tick() => controller.add(window.remainingUntilSend(widget._clock()));
    tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    _countdown = controller;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_countdown?.close());
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    try {
      await launchUrl(Uri.parse('whatsapp://'));
    } on Object {
      // Not installed (or blocked): silently do nothing (§4.2).
    }
  }

  Future<void> _contactSupport() async {
    try {
      await launchUrl(Uri.parse('tel:${widget.supportPhone}'));
    } on Object {
      // No dialer: silently do nothing.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return BlocBuilder<PhoneVerificationCubit, PvState>(
      builder: (context, state) {
        // Blocked renders the same step from its snapshot, disabled (T064).
        final (code, blocked) = switch (state) {
          PvCode() => (state, false),
          PvBlocked(:final code) when code != null => (code, true),
          _ => (null, false),
        };
        if (code == null) return const SizedBox.shrink();
        _retune(code.challenge.window);
        final countdown = _countdown!;
        if (_codeController.text != code.code) {
          _codeController.text = code.code;
        }
        final cubit = context.read<PhoneVerificationCubit>();
        final noticeMessage = blocked
            ? null
            : switch (code.notice) {
                PvNotice.notOnWhatsApp => l10n.whatsappNotOnWhatsApp,
                PvNotice.attestationFailed => l10n.otpAttestationFailed,
                PvNotice.temporarilyUnavailable =>
                  l10n.otpTemporarilyUnavailable,
                null => null,
              };
        final failure = code.error;
        final error = blocked || failure == null
            ? null
            : phoneVerificationErrorText(failure, l10n);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.whatsappCodeTitle,
              key: const ValueKey('whatsapp-code-title'),
              style: context.textStyles.authTitle,
            ),
            const SizedBox(height: Dimens.space12),
            Text(
              // A rate-limited first send never went out: say so instead
              // of «بعتنا كود» (review round 2).
              code.codeSent
                  ? l10n.whatsappCodeSentTo(code.challenge.maskedPhone)
                  : l10n.whatsappNotSentYet(code.challenge.maskedPhone),
              style: context.textStyles.authDescription.copyWith(
                color: colors['textMuted'],
              ),
            ),
            const SizedBox(height: Dimens.space32),
            if (noticeMessage != null) ...[
              NoticeCard(
                icon: AppIcons.errorOutline,
                message: noticeMessage,
                actionLabel: l10n.whatsappContactSupport,
                onAction: _contactSupport,
              ),
              const SizedBox(height: Dimens.space16),
            ],
            OnAirOtpField(
              key: const ValueKey('whatsapp-otp-field'),
              controller: _codeController,
              enabled:
                  !blocked &&
                  code.codeSent &&
                  code.codeFieldEnabled &&
                  !code.verifying,
              onCompleted: (_) => cubit.verify(),
              onChanged: cubit.onCodeChanged,
            ),
            if (error != null) ...[
              const SizedBox(height: Dimens.space8),
              Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  key: const ValueKey('whatsapp-code-error'),
                  style: TextStyle(color: colors.errorText),
                ),
              ),
            ],
            const SizedBox(height: Dimens.space24),
            Center(
              child: SizedBox(
                width: 230,
                child: OnAirPrimaryButton(
                  key: const ValueKey('whatsapp-confirm'),
                  label: l10n.whatsappConfirm,
                  onPressed:
                      !blocked &&
                          code.codeSent &&
                          code.code.length == 6 &&
                          code.codeFieldEnabled &&
                          !code.verifying
                      ? cubit.verify
                      : null,
                  isLoading: code.verifying,
                  gradient: true,
                  pill: true,
                  height: 62,
                ),
              ),
            ),
            const SizedBox(height: Dimens.space12),
            Center(
              child: OutlinedButton(
                key: const ValueKey('whatsapp-open'),
                onPressed: _openWhatsApp,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors['textAccent'],
                  shape: const StadiumBorder(),
                  side: BorderSide(color: colors['border']),
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: Dimens.space24,
                    vertical: Dimens.space12,
                  ),
                ),
                child: Text(l10n.whatsappOpen),
              ),
            ),
            const SizedBox(height: Dimens.space16),
            // The server's window decides the wait (Constitution II): while
            // the remaining time is ahead the resend is disabled and shows
            // the rendered time; the per-second stream rebuilds the text
            // alone and flips the button once the wait is over.
            StreamBuilder<Duration>(
              stream: countdown.stream,
              builder: (context, snapshot) {
                final remaining = snapshot.hasData
                    ? snapshot.data!
                    : code.challenge.window.remainingUntilSend(widget._clock());
                final counting = remaining > Duration.zero;
                // The first frame falls back to the window's own remaining:
                // the broadcast stream's seed event lands before the
                // subscription.
                return TextButton(
                  key: const ValueKey('whatsapp-resend'),
                  onPressed:
                      counting || blocked || code.resending || code.verifying
                      ? null
                      : cubit.resend,
                  style: TextButton.styleFrom(
                    foregroundColor: colors['textAccent'],
                  ),
                  child: counting
                      ? Semantics(
                          // The ticking time is screen-reader noise: the
                          // button keeps one static label while it waits
                          // (T079).
                          label: l10n.whatsappResend,
                          excludeSemantics: true,
                          child: Text(
                            l10n.whatsappResendIn(
                              formatSendWait(remaining, l10n),
                            ),
                          ),
                        )
                      : Text(l10n.whatsappResend),
                );
              },
            ),
            const SizedBox(height: Dimens.space8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  key: const ValueKey('whatsapp-edit-number'),
                  onPressed: blocked || code.resending || code.verifying
                      ? null
                      : cubit.editNumber,
                  style: TextButton.styleFrom(
                    foregroundColor: colors['textAccent'],
                  ),
                  child: Text(l10n.whatsappEditNumber),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

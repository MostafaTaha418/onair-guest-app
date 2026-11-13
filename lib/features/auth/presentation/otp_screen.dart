import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/redirect.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/platform/secure_screen.dart';
import 'package:on_air/design_system/components/on_air_otp_field.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/auth/presentation/auth_error_message.dart';
import 'package:on_air/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:on_air/features/auth/presentation/widgets/auth_flow_scaffold.dart';
import 'package:on_air/features/auth/presentation/widgets/rapid_submit_guard.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class OtpScreen extends StatefulWidget {
  const OtpScreen({
    this.secureScreen = const SecureScreen(),
    this.clock = DateTime.now,
    super.key,
  });

  final SecureScreenControl secureScreen;
  final DateTime Function() clock;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

final class _OtpScreenState extends State<OtpScreen> {
  final _controller = TextEditingController();
  Timer? _ticker;
  bool _submitting = false;
  bool _resending = false;
  bool _showValidation = false;
  final _verifyGuard = RapidSubmitGuard();
  final _resendGuard = RapidSubmitGuard();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_verifyGuard.reset);
    unawaited(widget.secureScreen.setSecure(enabled: true));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
        context.read<AuthCubit>().resumeCodeEntry();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    unawaited(widget.secureScreen.setSecure(enabled: false));
    super.dispose();
  }

  Future<void> _verify(String code) async {
    if (code.length != 6) {
      setState(() => _showValidation = true);
      return;
    }
    if (_submitting || !_verifyGuard.tryEnter()) return;
    setState(() {
      _showValidation = false;
      _submitting = true;
    });
    final cubit = context.read<AuthCubit>();
    final channel = switch (cubit.state) {
      CodeSent(:final challenge) => challenge.channel,
      RateLimited(:final challenge) => challenge.channel,
      _ => null,
    };
    switch (channel) {
      case VerificationChannel.emailSignup:
        await cubit.verifyEmailCode(code);
      case VerificationChannel.emailRecovery:
        await cubit.verifyRecovery(code);
      case null:
        break;
    }
    if (!mounted) return;
    final state = cubit.state;
    final router = GoRouter.maybeOf(context);
    if (state is RecoveryVerified) {
      router?.go(AppRoutes.newPassword);
      return;
    }
    if (state is SignedIn) {
      if (router != null) {
        final origin = GoRouterState.of(context).uri.queryParameters['from'];
        final destination = resolveAuthReturnDestination(origin);
        router.go(
          state.isComplete
              ? destination
              : Uri(
                  path: AppRoutes.completeProfile,
                  queryParameters: {'from': destination},
                ).toString(),
        );
      }
      return;
    }
    setState(() => _submitting = false);
  }

  Future<void> _resend(CodeChallenge challenge) async {
    if (_resending || _submitting || !_resendGuard.tryEnter()) return;
    setState(() => _resending = true);
    _controller.clear();
    _showValidation = false;
    final cubit = context.read<AuthCubit>();
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      switch (challenge.channel) {
        case VerificationChannel.emailSignup:
          await cubit.requestEmailVerification(challenge.target);
        case VerificationChannel.emailRecovery:
          await cubit.requestRecovery(challenge.target);
      }
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(authErrorMessage(error, l10n))),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _changeTarget(VerificationChannel channel) {
    _controller.clear();
    context.read<AuthCubit>().cancelCodeEntry();
    GoRouter.maybeOf(context)?.go(
      channel == VerificationChannel.emailRecovery
          ? AppRoutes.forgotPassword
          : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).height < 700;
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final challenge = switch (state) {
          CodeSent(:final challenge) => challenge,
          RateLimited(:final challenge) => challenge,
          _ => null,
        };
        if (challenge == null) return const SizedBox.shrink();
        final deadline = switch (state) {
          RateLimited(:final until) => until,
          _ => challenge.resendAt,
        };
        final seconds = deadline
            .difference(widget.clock())
            .inSeconds
            .clamp(
              0,
              86400,
            );
        final isRateLimited = state is RateLimited;
        final errorCode = state is CodeSent ? state.errorCode : null;
        final error = switch (errorCode) {
          'OTP_EXPIRED' => l10n.authOtpExpired,
          'OTP_INVALID' => l10n.authOtpInvalid,
          AuthCubit.networkError => l10n.errorNoConnection,
          AuthCubit.unexpectedError => l10n.errorUnexpectedNoRef,
          _ => null,
        };
        return AuthFlowScaffold(
          topSpaceFactor: 0.08,
          minTopSpace: compact ? 24 : 40,
          maxTopSpace: 56,
          onBack: () => _changeTarget(challenge.channel),
          children: [
            const AuthBrandHeader(),
            SizedBox(height: compact ? Dimens.space24 : Dimens.space32),
            Text(l10n.authCodeTitle, style: context.textStyles.authTitle),
            const SizedBox(height: Dimens.space12),
            Text(
              l10n.authCodeDescription(challenge.target),
              style: context.textStyles.authDescription.copyWith(
                color: context.colors['textMuted'],
              ),
            ),
            SizedBox(height: compact ? Dimens.space32 : Dimens.space48),
            OnAirOtpField(
              key: const ValueKey('otp-field'),
              controller: _controller,
              enabled: !isRateLimited && !_submitting,
              onCompleted: _verify,
              onChanged: (_) => setState(() {}),
            ),
            if (_showValidation && _controller.text.length != 6) ...[
              const SizedBox(height: Dimens.space8),
              Semantics(
                liveRegion: true,
                child: Text(
                  _controller.text.isEmpty
                      ? l10n.authCodeRequired
                      : l10n.authCodeIncomplete,
                  key: const ValueKey('otp-local-error'),
                  style: TextStyle(color: context.colors.errorText),
                ),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: Dimens.space8),
              Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  key: const ValueKey('otp-error'),
                  style: TextStyle(color: context.colors.errorText),
                ),
              ),
            ],
            if (isRateLimited) ...[
              const SizedBox(height: Dimens.space8),
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.authRateLimited(l10n.authWaitSeconds(seconds)),
                ),
              ),
            ],
            const SizedBox(height: Dimens.space16),
            TextButton(
              key: const ValueKey('resend-button'),
              onPressed: seconds == 0 && !isRateLimited && !_resending
                  ? () => _resend(challenge)
                  : null,
              style: TextButton.styleFrom(
                foregroundColor: context.colors['textAccent'],
              ),
              child: Text(
                seconds == 0 && !isRateLimited
                    ? l10n.authResend
                    : l10n.authResendIn(l10n.authWaitSeconds(seconds)),
              ),
            ),
            const SizedBox(height: Dimens.space32),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SizedBox(
                width: 185,
                child: OnAirPrimaryButton(
                  key: const ValueKey('verify-code-button'),
                  label: l10n.confirm,
                  onPressed: !isRateLimited && !_submitting
                      ? () => _verify(_controller.text)
                      : null,
                  isLoading: _submitting,
                  gradient: true,
                  pill: true,
                  height: 62,
                ),
              ),
            ),
            const SizedBox(height: Dimens.space16),
            TextButton(
              key: const ValueKey('change-email-button'),
              onPressed: () => _changeTarget(challenge.channel),
              style: TextButton.styleFrom(
                foregroundColor: context.colors['textAccent'],
              ),
              child: Text(l10n.authChangeEmail),
            ),
          ],
        );
      },
    );
  }
}

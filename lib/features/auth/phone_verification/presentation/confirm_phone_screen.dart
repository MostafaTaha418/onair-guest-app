import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/redirect.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/features/auth/phone_verification/presentation/phone_verification_cubit.dart';
import 'package:on_air/features/auth/phone_verification/presentation/widgets/phone_form_step.dart';
import 'package:on_air/features/auth/phone_verification/presentation/widgets/send_window_notice.dart';
import 'package:on_air/features/auth/phone_verification/presentation/widgets/whatsapp_code_step.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:on_air/features/auth/presentation/widgets/auth_flow_scaffold.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// «أكّد رقمك»: the mandatory WhatsApp phone confirmation. It cannot be
/// skipped, and leaving `register` signs the guest out (FR-013, FR-014).
/// The cubit comes from the route builder (T047); the same screen serves the
/// change-number route (`purpose: change`, phone field only).
final class ConfirmPhoneScreen extends StatefulWidget {
  const ConfirmPhoneScreen({required this.purpose, this.from, super.key});

  final PhoneVerificationPurpose purpose;
  final String? from;

  @override
  State<ConfirmPhoneScreen> createState() => _ConfirmPhoneScreenState();
}

class _ConfirmPhoneScreenState extends State<ConfirmPhoneScreen> {
  String? _supportPhone;
  bool _configFailed = false;

  @override
  void initState() {
    super.initState();
    // The terms version and the support phone come from the server
    // config, like the old completion step did (T046).
    unawaited(_loadConfig());
  }

  Future<void> _loadConfig() async {
    try {
      final config = await context.read<AppConfigSource>().load();
      if (!mounted) return;
      context.read<PhoneVerificationCubit>().termsVersion =
          config.currentTermsVersion;
      setState(() {
        _supportPhone = config.supportPhone;
        _configFailed = false;
      });
    } on Object {
      // The terms gate stays shut without the server's version; the retry
      // button re-reads the config (review fix 9).
      if (!mounted) return;
      setState(() => _configFailed = true);
    }
  }

  bool get _isRegister => widget.purpose == PhoneVerificationPurpose.register;

  /// The blocked state's «كلّم الدعم» dials the config support phone (§4.3).
  Future<void> _contactSupport() async {
    final phone = _supportPhone;
    if (phone == null || phone.isEmpty) return;
    try {
      await launchUrl(Uri.parse('tel:$phone'));
    } on Object {
      // No dialer: silently do nothing.
    }
  }

  /// The blocked register flow's «تسجيل الخروج»: the half-made account never
  /// survives (FR-014) — the button itself is the confirmation.
  Future<void> _signOutFromBlock() async {
    await context.read<AuthCubit>().signOut();
    if (!mounted) return;
    context.go(resolveAuthCancelDestination(widget.from));
  }

  /// The account snapshot the route builder classified the cubit with.
  GuestAccount? get _account {
    final state = context.read<AuthCubit>().state;
    return state is SignedIn ? state.account : null;
  }

  Future<void> _leaveDialog() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmPhoneLeaveTitle),
        content: Text(l10n.confirmPhoneLeaveBody),
        actions: [
          TextButton(
            key: const ValueKey('confirm-phone-leave-stay'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.confirmPhoneLeaveStay),
          ),
          TextButton(
            key: const ValueKey('confirm-phone-leave-confirm'),
            style: TextButton.styleFrom(
              foregroundColor: context.colors['destructive'],
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirmPhoneLeaveConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // Leaving registration never keeps the half-made account (FR-014).
    await context.read<AuthCubit>().signOut();
    if (!mounted) return;
    context.go(resolveAuthCancelDestination(widget.from));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final account = _account;
    final needsName = account?.fullName == null;
    final needsTerms = account?.acceptedTermsVersion == null;
    final showEmailRow =
        _isRegister && (needsName || needsTerms) && account?.email != null;
    final form = PhoneFormStep(needsName: needsName, needsTerms: needsTerms);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          // The change flow's title is «رقم جديد»; register keeps «أكّد
          // رقمك» (review extra: one title per screen, no AppBar duplicate).
          _isRegister ? l10n.confirmPhoneTitle : l10n.confirmPhoneNewTitle,
          key: const ValueKey('confirm-phone-title'),
          style: context.textStyles.authTitle,
        ),
        const SizedBox(height: Dimens.space12),
        Text(
          l10n.confirmPhoneSubtitle,
          style: context.textStyles.authDescription.copyWith(
            color: context.colors['textMuted'],
          ),
        ),
        if (_configFailed) ...[
          const SizedBox(height: Dimens.space12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.errorNoConnection,
                  key: const ValueKey('config-error'),
                  style: context.textStyles.authDescription.copyWith(
                    color: context.colors.errorText,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('config-retry'),
                onPressed: () => unawaited(_loadConfig()),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ],
        const SizedBox(height: Dimens.space24),
        if (showEmailRow) ...[
          _EmailRow(email: account!.email!),
          const SizedBox(height: Dimens.space20),
        ],
        BlocBuilder<PhoneVerificationCubit, PvState>(
          builder: (context, state) => switch (state) {
            // The block notice sits above the interrupted step; both steps
            // render their send/confirm controls disabled (§4.3, T064).
            PvBlocked() => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BlockedNotice(
                  blockedUntil: state.blockedUntil,
                  onSupport: () => unawaited(_contactSupport()),
                  onSignOut: _isRegister
                      ? () => unawaited(_signOutFromBlock())
                      : null,
                ),
                const SizedBox(height: Dimens.space16),
                if (state.code != null)
                  WhatsAppCodeStep(supportPhone: _supportPhone ?? '')
                else
                  form,
              ],
            ),
            PvCode() => WhatsAppCodeStep(
              supportPhone: _supportPhone ?? '',
            ),
            _ => form,
          },
        ),
      ],
    );

    return BlocListener<PhoneVerificationCubit, PvState>(
      listener: (context, state) {
        if (state is! PvDone) return;
        unawaited(_onConfirmed(state));
      },
      child: _isRegister
          ? PopScope(
              // Registration cannot be backed out of silently (FR-014).
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;
                unawaited(_leaveDialog());
              },
              child: AuthFlowScaffold(
                topSpaceFactor: 0.08,
                minTopSpace: 24,
                maxTopSpace: 56,
                onBack: () => unawaited(_leaveDialog()),
                children: [
                  const AuthBrandHeader(),
                  const SizedBox(height: Dimens.space32),
                  content,
                ],
              ),
            )
          : Scaffold(
              appBar: AppBar(),
              body: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(Dimens.screenSide),
                  children: [content],
                ),
              ),
            ),
    );
  }

  /// T056: `register` refreshes the account and lets the router release
  /// the guest to `from` (a snackbar confirms); the guest is navigated
  /// only if the redirect has not already done it. `change` pops with
  /// `true` and confirms with a snackbar.
  Future<void> _onConfirmed(PvDone state) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthCubit>();
    // The flow returns the fresh profile: publish it immediately (review
    // fix 7) and let refreshAccount confirm in the background.
    // ignore: cascade_invocations
    auth.applyAccount(state.account);
    if (state.purpose == PhoneVerificationPurpose.register) {
      unawaited(auth.refreshAccount());
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.confirmPhoneWelcome)),
      );
      // Still here? The redirect could not run (e.g. the guest landed on
      // a non-routed surface) — release them to the return destination.
      if (mounted &&
          GoRouterState.of(context).uri.path == AppRoutes.completeProfile) {
        context.go(resolveAuthReturnDestination(widget.from));
      }
    } else {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.phoneChanged)),
      );
      context.pop(true);
    }
  }
}

final class _EmailRow extends StatelessWidget {
  const _EmailRow({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Container(
      key: const ValueKey('confirm-phone-email'),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: Dimens.space16,
        vertical: Dimens.space12,
      ),
      decoration: BoxDecoration(
        color: colors['socialFill'],
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: colors['border']),
      ),
      child: Row(
        children: [
          Icon(
            AppIcons.mailOutlineRounded,
            size: 20,
            color: colors['textMuted'],
          ),
          const SizedBox(width: Dimens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.confirmPhoneEmailLabel,
                  style: context.textStyles.placeholder.copyWith(
                    color: colors['textMuted'],
                  ),
                ),
                Text(email, style: context.textStyles.input),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

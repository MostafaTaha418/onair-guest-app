import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/design_system/components/info_banner.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/bookings/presentation/unfinished_payment_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Where the banner sits: Home keeps the shared [InfoBanner]; My Bookings
/// uses the compact warning strip from the 2026-11 redesign.
enum UnfinishedPaymentBannerLayout { standard, bookings }

/// The unfinished-payment banner (US6): shown on Home and My Bookings while
/// a payment is still pending on the server; opens the attempt's status.
/// Harnesses that pump the screens without the app-scoped cubit show nothing.
final class UnfinishedPaymentBanner extends StatefulWidget {
  const UnfinishedPaymentBanner({
    this.layout = UnfinishedPaymentBannerLayout.standard,
    super.key,
  });

  final UnfinishedPaymentBannerLayout layout;

  @override
  State<UnfinishedPaymentBanner> createState() =>
      _UnfinishedPaymentBannerState();
}

final class _UnfinishedPaymentBannerState
    extends State<UnfinishedPaymentBanner> {
  /// The target lookup is asynchronous; a second tap while it runs would
  /// push the same screen twice.
  var _opening = false;

  UnfinishedPaymentCubit? _cubit(BuildContext context) {
    try {
      return context.read<UnfinishedPaymentCubit>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  Future<void> _open(UnfinishedPaymentCubit cubit, UnfinishedSome state) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final target = await cubit.targetFor(state.booking);
      if (mounted) unawaited(context.push(target));
    } finally {
      if (mounted) setState(() => _opening = false);
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
        final onAction = _opening ? null : () => _open(cubit, state);
        if (widget.layout == UnfinishedPaymentBannerLayout.bookings) {
          return _BookingsBanner(
            message: l10n.unfinishedPaymentBanner,
            actionLabel: l10n.unfinishedPaymentOpen,
            onAction: onAction,
          );
        }
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
            onAction: onAction,
          ),
        );
      },
    );
  }
}

final class _BookingsBanner extends StatelessWidget {
  const _BookingsBanner({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Primary text on the warning container keeps AA contrast in both themes.
    final foreground = colors.textPrimary;
    final text = Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontSize: 14,
      color: foreground,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        Dimens.screenSide,
        Dimens.space12,
        Dimens.screenSide,
        0,
      ),
      child: Semantics(
        liveRegion: true,
        container: true,
        child: Material(
          color: colors['warningContainer'],
          borderRadius: BorderRadius.circular(Dimens.radiusField),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: Dimens.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                Dimens.space12,
                Dimens.space4,
                Dimens.space4,
                Dimens.space4,
              ),
              child: Row(
                children: [
                  Icon(AppIcons.infoOutline, size: 20, color: foreground),
                  const SizedBox(width: Dimens.space8),
                  Expanded(
                    child: Text(
                      message,
                      style: text.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: foreground,
                      disabledForegroundColor: foreground.withValues(
                        alpha: 0.38,
                      ),
                      minimumSize: const Size(48, 40),
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimens.radiusField),
                      ),
                      overlayColor: const Color(0xFF000000),
                      textStyle: text.copyWith(
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    child: Text(actionLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Dimens.space16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 24, width: 160, color: context.colors['detailCard']),
        const SizedBox(height: Dimens.space16),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: context.colors['detailCard'],
            borderRadius: BorderRadius.circular(Dimens.radiusCard),
          ),
        ),
        const SizedBox(height: Dimens.space16),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: context.colors['detailCard'],
            borderRadius: BorderRadius.circular(Dimens.radiusCard),
          ),
        ),
      ],
    ),
  );
}

final class EmptyView extends StatelessWidget {
  const EmptyView({
    required this.icon,
    required this.message,
    this.action,
    super.key,
  });
  final IconData icon;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: context.colors.textSecondary),
        const SizedBox(height: Dimens.space12),
        Text(message, textAlign: TextAlign.center),
        ?action,
      ],
    ),
  );
}

final class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.message,
    required this.onRetry,
    this.referenceNumber,
    super.key,
  });
  final String message;
  final VoidCallback onRetry;
  final String? referenceNumber;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: context.colors.errorText),
          Text(message, textAlign: TextAlign.center),
          if (referenceNumber != null)
            Text(l10n.referenceNumber(referenceNumber!)),
          TextButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}

final class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});
  @override
  Widget build(BuildContext context) => Material(
    color: context.colors['warningContainer'],
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(Dimens.space8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, color: context.colors['onWarningContainer']),
            const SizedBox(width: Dimens.space8),
            Text(
              AppLocalizations.of(context).offline,
              style: TextStyle(color: context.colors['onWarningContainer']),
            ),
          ],
        ),
      ),
    ),
  );
}

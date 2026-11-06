import 'package:flutter/material.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

final class OnAirConfirmSheet extends StatelessWidget {
  const OnAirConfirmSheet({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    this.isLoading = false,
    this.errorText,
    this.extraActionLabel,
    this.onExtraAction,
    super.key,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final bool isLoading;

  /// An error announced to screen readers and rendered under the body.
  final String? errorText;
  final String? extraActionLabel;
  final VoidCallback? onExtraAction;

  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) => showModalBottomSheet<T>(
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
    builder: builder,
  );

  @override
  Widget build(BuildContext context) => SafeArea(
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
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: Dimens.space8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: Dimens.space8),
            Semantics(
              liveRegion: true,
              child: Text(
                errorText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.errorText,
                ),
              ),
            ),
          ],
          const SizedBox(height: Dimens.space24),
          OnAirPrimaryButton(
            label: confirmLabel,
            onPressed: isLoading ? null : onConfirm,
            isLoading: isLoading,
          ),
          const SizedBox(height: Dimens.space8),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(64, Dimens.minTouchTarget),
            ),
            onPressed: isLoading ? null : () => Navigator.of(context).pop(),
            child: Text(cancelLabel),
          ),
          if (extraActionLabel != null)
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(64, Dimens.minTouchTarget),
              ),
              onPressed: isLoading ? null : onExtraAction,
              child: Text(extraActionLabel!),
            ),
        ],
      ),
    ),
  );
}

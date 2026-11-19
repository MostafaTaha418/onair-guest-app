import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

enum AttachmentTileKind { image, pdf }

enum AttachmentTileState { preparing, uploading, failed, ready }

typedef AttachmentImageBuilder = Widget Function(BuildContext context);

final class AttachmentTile extends StatelessWidget {
  const AttachmentTile({
    required this.kind,
    required this.name,
    required this.sizeLabel,
    this.state = AttachmentTileState.ready,
    this.progress = 0,
    this.imageBuilder,
    this.onRemove,
    this.onRetry,
    this.size = 72,
    super.key,
  });

  final AttachmentTileKind kind;
  final String name;
  final String sizeLabel;
  final AttachmentTileState state;
  final double progress;
  final AttachmentImageBuilder? imageBuilder;
  final VoidCallback? onRemove;
  final VoidCallback? onRetry;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: '$name، $sizeLabel',
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors['cancelledBackground'],
            borderRadius: BorderRadius.circular(Dimens.radiusField),
            border: Border.all(
              color: state == AttachmentTileState.failed
                  ? colors.errorText
                  : colors.border,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Dimens.radiusField - 1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (kind == AttachmentTileKind.image && imageBuilder != null)
                  imageBuilder!(context)
                else
                  Center(
                    child: Icon(
                      kind == AttachmentTileKind.pdf
                          ? Icons.picture_as_pdf_outlined
                          : Icons.image_outlined,
                      color: colors.primary,
                      size: 30,
                    ),
                  ),
                PositionedDirectional(
                  start: Dimens.space4,
                  end: Dimens.space4,
                  bottom: Dimens.space4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(Dimens.radiusChip),
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: Dimens.space4,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            sizeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (state == AttachmentTileState.preparing ||
                    state == AttachmentTileState.uploading)
                  ColoredBox(
                    color: colors.surface.withValues(alpha: .78),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          value: state == AttachmentTileState.uploading
                              ? progress.clamp(0, 1)
                              : null,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),
                if (state == AttachmentTileState.failed)
                  ColoredBox(
                    color: colors.surface.withValues(alpha: .88),
                    child: Semantics(
                      button: true,
                      label: l10n.supportAttachRetry,
                      child: InkWell(
                        onTap: onRetry,
                        child: Center(
                          child: Icon(Icons.refresh, color: colors.errorText),
                        ),
                      ),
                    ),
                  ),
                if (onRemove != null)
                  PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: Semantics(
                      button: true,
                      label: l10n.supportAttachRemove,
                      child: SizedBox(
                        width: Dimens.minTouchTarget,
                        height: Dimens.minTouchTarget,
                        child: Align(
                          alignment: AlignmentDirectional.topEnd,
                          child: Material(
                            color: colors.surface,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: onRemove,
                              child: const Padding(
                                padding: EdgeInsetsDirectional.all(
                                  Dimens.space4,
                                ),
                                child: Icon(Icons.close, size: 16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

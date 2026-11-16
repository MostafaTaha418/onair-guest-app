import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:on_air/core/files/attachment_picker.dart';
import 'package:on_air/core/files/image_sanitizer.dart';
import 'package:on_air/core/files/private_file_uploader.dart';
import 'package:on_air/core/files/upload_limits.dart';
import 'package:on_air/design_system/components/attachment_tile.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/support/domain/attachment_draft.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:uuid/uuid.dart';

enum AttachmentPickSource { camera, gallery, pdf }

final class AttachmentStrip extends StatefulWidget {
  const AttachmentStrip({
    required this.draftId,
    required this.attachments,
    required this.onChanged,
    required this.picker,
    required this.sanitizer,
    required this.uploader,
    this.limits = const UploadLimits(),
    this.enabled = true,
    super.key,
  });

  final String draftId;
  final List<AttachmentDraft> attachments;
  final ValueChanged<List<AttachmentDraft>> onChanged;
  final AttachmentPicker picker;
  final ImageSanitizer sanitizer;
  final PrivateFileUploader uploader;
  final UploadLimits limits;
  final bool enabled;

  @override
  State<AttachmentStrip> createState() => _AttachmentStripState();
}

final class _AttachmentStripState extends State<AttachmentStrip> {
  Future<void> _choose() async {
    if (!widget.enabled) return;
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<AttachmentPickSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.supportAttachCamera),
              onTap: () => Navigator.pop(
                context,
                AttachmentPickSource.camera,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.supportAttachGallery),
              onTap: () => Navigator.pop(
                context,
                AttachmentPickSource.gallery,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(l10n.supportAttachPdf),
              onTap: () => Navigator.pop(context, AttachmentPickSource.pdf),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final remaining = widget.limits.maxFiles - widget.attachments.length;
    final picked = switch (source) {
      AttachmentPickSource.camera => await widget.picker.pickCamera(),
      AttachmentPickSource.gallery => await widget.picker.pickGallery(
        max: remaining,
      ),
      AttachmentPickSource.pdf => await widget.picker.pickPdf(),
    };
    for (final file in picked) {
      if (!mounted) return;
      await _prepare(file);
    }
  }

  Future<void> _prepare(PickedFile file) async {
    final kind = file.mime == 'application/pdf'
        ? AttachmentKind.pdf
        : file.mime.startsWith('image/')
        ? AttachmentKind.image
        : AttachmentKind.unsupported;
    final check = widget.limits.validate(
      kind: kind,
      sizeBytes: file.sizeBytes,
      currentCount: widget.attachments.length,
    );
    if (check.type != AttachmentCheckType.ok) {
      _showRejection(check);
      return;
    }
    final localId = const Uuid().v4();
    var draft = AttachmentDraft(
      localId: localId,
      kind: kind,
      displayName: file.name,
      tempPath: file.path,
      sizeBytes: file.sizeBytes,
      state: const AttachmentUploadState.preparing(),
    );
    _replace(draft);
    try {
      final prepared = await widget.sanitizer.prepare(file);
      final afterPrepare = widget.limits.validate(
        kind: kind,
        sizeBytes: prepared.sizeBytes,
        currentCount: widget.attachments
            .where((item) => item.localId != localId)
            .length,
      );
      if (afterPrepare.type != AttachmentCheckType.ok) {
        await widget.uploader.abandon(prepared);
        _remove(localId);
        _showRejection(afterPrepare);
        return;
      }
      final token = CancelToken();
      draft = draft.copyWith(
        tempPath: prepared.tempPath,
        sizeBytes: prepared.sizeBytes,
        state: const AttachmentUploadState.uploading(0),
        cancelToken: token,
      );
      _replace(draft);
      await for (final progress in widget.uploader.upload(
        prepared,
        draftId: widget.draftId,
        cancelToken: token,
      )) {
        if (!mounted) return;
        final state = switch (progress.stage) {
          UploadStage.preparing => const AttachmentUploadState.preparing(),
          UploadStage.uploading => AttachmentUploadState.uploading(
            progress.fraction ?? 0,
          ),
          UploadStage.uploaded => AttachmentUploadState.uploaded(
            progress.attachmentId!,
          ),
          UploadStage.cancelled => const AttachmentUploadState.failed(
            UploadFailureReason.unknown,
          ),
          UploadStage.failed => AttachmentUploadState.failed(
            progress.failure ?? UploadFailureReason.unknown,
          ),
        };
        draft = draft.copyWith(state: state);
        _replace(draft);
      }
    } on Object {
      _replace(
        draft.copyWith(
          state: const AttachmentUploadState.failed(
            UploadFailureReason.unknown,
          ),
        ),
      );
    }
  }

  void _replace(AttachmentDraft draft) {
    final items = [...widget.attachments];
    final index = items.indexWhere((item) => item.localId == draft.localId);
    if (index < 0) {
      items.add(draft);
    } else {
      items[index] = draft;
    }
    widget.onChanged(items);
  }

  void _remove(String localId) {
    final item = widget.attachments
        .where((value) => value.localId == localId)
        .firstOrNull;
    item?.cancelToken?.cancel();
    widget.onChanged(
      widget.attachments.where((value) => value.localId != localId).toList(),
    );
  }

  void _retry(AttachmentDraft draft) {
    final mime = draft.kind == AttachmentKind.pdf
        ? 'application/pdf'
        : 'image/jpeg';
    _remove(draft.localId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        _prepare(
          PickedFile(
            path: draft.tempPath,
            name: draft.displayName,
            sizeBytes: draft.sizeBytes,
            mime: mime,
          ),
        ),
      );
    });
  }

  void _showRejection(AttachmentCheck check) {
    final l10n = AppLocalizations.of(context);
    final message = switch (check.type) {
      AttachmentCheckType.tooLarge => l10n.supportAttachmentRejectedTooLarge(
        check.limit!,
      ),
      AttachmentCheckType.tooMany => l10n.supportAttachmentRejectedTooMany(
        check.limit!,
      ),
      AttachmentCheckType.typeNotAllowed => l10n.supportAttachmentRejectedType,
      AttachmentCheckType.ok => '',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.attachments.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: Dimens.space8),
            itemBuilder: (context, index) {
              if (index == widget.attachments.length) {
                return Semantics(
                  button: true,
                  label: l10n.supportAttach,
                  child: SizedBox.square(
                    dimension: 72,
                    child: OutlinedButton(
                      onPressed:
                          widget.enabled &&
                              widget.attachments.length < widget.limits.maxFiles
                          ? _choose
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(Dimens.space4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add),
                          Text(l10n.supportAttach),
                        ],
                      ),
                    ),
                  ),
                );
              }
              final item = widget.attachments[index];
              return AttachmentTile(
                kind: item.kind == AttachmentKind.pdf
                    ? AttachmentTileKind.pdf
                    : AttachmentTileKind.image,
                name: item.displayName,
                sizeLabel: '${(item.sizeBytes / 1024).ceil()} KB',
                state: switch (item.state.phase) {
                  AttachmentUploadPhase.preparing =>
                    AttachmentTileState.preparing,
                  AttachmentUploadPhase.uploading =>
                    AttachmentTileState.uploading,
                  AttachmentUploadPhase.uploaded => AttachmentTileState.ready,
                  AttachmentUploadPhase.failed => AttachmentTileState.failed,
                },
                progress: item.state.progress,
                onRemove: widget.enabled ? () => _remove(item.localId) : null,
                onRetry: widget.enabled ? () => _retry(item) : null,
              );
            },
          ),
        ),
        const SizedBox(height: Dimens.space4),
        Text(
          l10n.supportAttachHint(widget.limits.maxFiles),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

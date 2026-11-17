import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
  /// The source of truth for the tiles. Upload progress and removals
  /// land here synchronously — `widget.attachments` only catches up when
  /// the parent rebuilds, so two stream events in one frame would
  /// otherwise erase each other.
  List<AttachmentDraft> _items = const [];

  /// Local ids the user removed; late events for them (a cancelled put,
  /// a sanitizer that finished late) must not resurrect the tile.
  final Set<String> _removed = {};

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.attachments);
  }

  @override
  void didUpdateWidget(covariant AttachmentStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent drives the list too (e.g. the composer clears it after
    // a send). Only an actually different list resyncs, so our own echo
    // never fights the local state. Removal tombstones stay: they are
    // one-off uuids and must outlive the echo of their own removal.
    if (!listEquals(oldWidget.attachments, widget.attachments)) {
      _items = List.of(widget.attachments);
    }
  }

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
    final remaining = widget.limits.maxFiles - _items.length;
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
      currentCount: _items.length,
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
    _replace(draft, insert: true);
    try {
      final prepared = await widget.sanitizer.prepare(file);
      if (!mounted || _removed.contains(localId)) {
        // Unmounted or removed while sanitizing: drop the prepared temp
        // file and never report a rejection for a tile that is gone.
        await widget.uploader.abandon(prepared);
        return;
      }
      final afterPrepare = widget.limits.validate(
        kind: kind,
        sizeBytes: prepared.sizeBytes,
        currentCount: _items.where((item) => item.localId != localId).length,
      );
      if (afterPrepare.type != AttachmentCheckType.ok) {
        await widget.uploader.abandon(prepared);
        if (!mounted) return;
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
        if (progress.stage == UploadStage.cancelled &&
            _removed.contains(localId)) {
          // The removal already removed the tile; do not turn it into a
          // failed one.
          continue;
        }
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
      if (!mounted) return;
      _replace(
        draft.copyWith(
          state: const AttachmentUploadState.failed(
            UploadFailureReason.unknown,
          ),
        ),
      );
    }
  }

  void _replace(AttachmentDraft draft, {bool insert = false}) {
    final index = _items.indexWhere((item) => item.localId == draft.localId);
    if (_removed.contains(draft.localId)) return;
    if (index < 0) {
      // Only the explicit first insert adds a tile; a late event for a
      // missing item is ignored.
      if (!insert) return;
      _items = [..._items, draft];
    } else {
      _items = [..._items]..[index] = draft;
    }
    setState(() {});
    widget.onChanged(List.of(_items));
  }

  void _remove(String localId) {
    final item = _items.where((value) => value.localId == localId).firstOrNull;
    item?.cancelToken?.cancel();
    _removed.add(localId);
    _items = _items
        .where((value) => value.localId != localId)
        .toList(growable: false);
    setState(() {});
    widget.onChanged(List.of(_items));
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
            itemCount: _items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: Dimens.space8),
            itemBuilder: (context, index) {
              if (index == _items.length) {
                return Semantics(
                  button: true,
                  label: l10n.supportAttach,
                  child: SizedBox.square(
                    dimension: 72,
                    child: OutlinedButton(
                      onPressed:
                          widget.enabled &&
                              _items.length < widget.limits.maxFiles
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
              final item = _items[index];
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

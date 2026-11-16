import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:on_air/core/files/private_file_uploader.dart';
import 'package:on_air/core/files/upload_limits.dart';

enum AttachmentUploadPhase { preparing, uploading, uploaded, failed }

@immutable
final class AttachmentUploadState {
  const AttachmentUploadState._(
    this.phase, {
    this.progress = 0,
    this.attachmentId,
    this.failure,
  });

  const AttachmentUploadState.preparing()
    : this._(AttachmentUploadPhase.preparing);
  const AttachmentUploadState.uploading(double progress)
    : this._(AttachmentUploadPhase.uploading, progress: progress);
  const AttachmentUploadState.uploaded(String attachmentId)
    : this._(AttachmentUploadPhase.uploaded, attachmentId: attachmentId);
  const AttachmentUploadState.failed(UploadFailureReason failure)
    : this._(AttachmentUploadPhase.failed, failure: failure);

  final AttachmentUploadPhase phase;
  final double progress;
  final String? attachmentId;
  final UploadFailureReason? failure;

  bool get isUploaded => phase == AttachmentUploadPhase.uploaded;
  bool get blocksSend => !isUploaded;
}

@immutable
final class AttachmentDraft {
  const AttachmentDraft({
    required this.localId,
    required this.kind,
    required this.displayName,
    required this.tempPath,
    required this.sizeBytes,
    required this.state,
    this.cancelToken,
  });

  final String localId;
  final AttachmentKind kind;
  final String displayName;
  final String tempPath;
  final int sizeBytes;
  final AttachmentUploadState state;
  final CancelToken? cancelToken;

  AttachmentDraft copyWith({
    String? tempPath,
    int? sizeBytes,
    AttachmentUploadState? state,
    CancelToken? cancelToken,
  }) => AttachmentDraft(
    localId: localId,
    kind: kind,
    displayName: displayName,
    tempPath: tempPath ?? this.tempPath,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    state: state ?? this.state,
    cancelToken: cancelToken ?? this.cancelToken,
  );
}

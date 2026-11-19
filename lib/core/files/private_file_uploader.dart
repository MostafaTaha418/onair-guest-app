import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:on_air/core/api/generated/fallback/fallback_client.dart';
import 'package:on_air/core/api/generated/models/entity_type.dart';
import 'package:on_air/core/api/generated/models/mime_type.dart';
import 'package:on_air/core/api/generated/models/v1_uploads_sign_request_body.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/files/image_sanitizer.dart';
import 'package:uuid/uuid.dart';

final class UploadSignRequest {
  const UploadSignRequest({
    required this.entityType,
    required this.entityId,
    required this.mime,
    required this.sizeBytes,
  });

  final String entityType;
  final String entityId;
  final String mime;
  final int sizeBytes;
}

final class UploadSignResponse {
  const UploadSignResponse({
    required this.attachmentId,
    required this.uploadUrl,
  });

  final String attachmentId;
  final Uri uploadUrl;
}

abstract interface class UploadSigner {
  Future<UploadSignResponse> sign(UploadSignRequest request);
}

final class GeneratedUploadSigner implements UploadSigner {
  GeneratedUploadSigner(this._client, {this.uuid = const Uuid()});

  final FallbackClient _client;
  final Uuid uuid;

  @override
  Future<UploadSignResponse> sign(UploadSignRequest request) async {
    final response = await _client.signUpload(
      xRequestId: uuid.v4(),
      body: V1UploadsSignRequestBody(
        entityType: EntityType.supportDraft,
        entityId: request.entityId,
        mimeType: MimeType.fromJson(request.mime),
        sizeBytes: request.sizeBytes,
      ),
    );
    return UploadSignResponse(
      attachmentId: response.attachmentId,
      uploadUrl: Uri.parse(response.uploadUrl),
    );
  }
}

abstract interface class RawPutClient {
  Future<void> put({
    required Uri url,
    required String filePath,
    required String mime,
    required int sizeBytes,
    required CancelToken cancelToken,
    required void Function(int sent, int total) onProgress,
  });
}

final class DioRawPutClient implements RawPutClient {
  DioRawPutClient([Dio? dio]) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  Future<void> put({
    required Uri url,
    required String filePath,
    required String mime,
    required int sizeBytes,
    required CancelToken cancelToken,
    required void Function(int sent, int total) onProgress,
  }) async {
    await _dio.put<void>(
      url.toString(),
      data: File(filePath).openRead(),
      options: Options(
        headers: {'Content-Type': mime, 'Content-Length': sizeBytes},
      ),
      cancelToken: cancelToken,
      onSendProgress: onProgress,
    );
  }
}

enum UploadStage { preparing, uploading, uploaded, failed, cancelled }

enum UploadFailureReason { tooLarge, typeNotAllowed, tooMany, network, unknown }

final class UploadProgress {
  const UploadProgress._(
    this.stage, {
    this.fraction,
    this.attachmentId,
    this.failure,
  });

  const UploadProgress.preparing() : this._(UploadStage.preparing);
  const UploadProgress.uploading(double fraction)
    : this._(UploadStage.uploading, fraction: fraction);
  const UploadProgress.uploaded(String attachmentId)
    : this._(UploadStage.uploaded, attachmentId: attachmentId);
  const UploadProgress.failed(UploadFailureReason reason)
    : this._(UploadStage.failed, failure: reason);
  const UploadProgress.cancelled() : this._(UploadStage.cancelled);

  final UploadStage stage;
  final double? fraction;
  final String? attachmentId;
  final UploadFailureReason? failure;
}

final class PrivateFileUploader {
  const PrivateFileUploader({
    required this.signer,
    required this.putClient,
  });

  final UploadSigner signer;
  final RawPutClient putClient;

  Stream<UploadProgress> upload(
    PreparedFile file, {
    required String draftId,
    CancelToken? cancelToken,
  }) {
    final controller = StreamController<UploadProgress>();
    final token = cancelToken ?? CancelToken();
    unawaited(_run(controller, file, draftId, token));
    return controller.stream;
  }

  Future<void> abandon(PreparedFile file) => _delete(file.tempPath);

  Future<void> _run(
    StreamController<UploadProgress> controller,
    PreparedFile file,
    String draftId,
    CancelToken token,
  ) async {
    controller.add(const UploadProgress.preparing());
    try {
      final signed = await signer.sign(
        UploadSignRequest(
          entityType: 'support_draft',
          entityId: draftId,
          mime: file.mime,
          sizeBytes: file.sizeBytes,
        ),
      );
      if (token.isCancelled) {
        throw DioException.requestCancelled(
          requestOptions: RequestOptions(path: signed.uploadUrl.toString()),
          reason: token.cancelError,
        );
      }
      controller.add(const UploadProgress.uploading(0));
      await putClient.put(
        url: signed.uploadUrl,
        filePath: file.tempPath,
        mime: file.mime,
        sizeBytes: file.sizeBytes,
        cancelToken: token,
        onProgress: (sent, total) {
          if (!controller.isClosed) {
            final denominator = total <= 0 ? file.sizeBytes : total;
            controller.add(
              UploadProgress.uploading(
                denominator <= 0 ? 0 : (sent / denominator).clamp(0, 1),
              ),
            );
          }
        },
      );
      await _delete(file.tempPath);
      controller.add(UploadProgress.uploaded(signed.attachmentId));
    } on Object catch (error) {
      if (_isCancelled(error, token)) {
        await _delete(file.tempPath);
        controller.add(const UploadProgress.cancelled());
      } else {
        controller.add(UploadProgress.failed(_failureReason(error)));
      }
    } finally {
      await controller.close();
    }
  }

  static bool _isCancelled(Object error, CancelToken token) =>
      token.isCancelled ||
      (error is DioException && CancelToken.isCancel(error));

  static UploadFailureReason _failureReason(Object error) {
    final apiError = switch (error) {
      AppFailure(:final error) => error,
      DioException(error: final ApiError value) => value,
      _ => null,
    };
    if (apiError?.code == ErrorCode.attachmentRejected) {
      return switch (apiError?.details?['reason']) {
        'too_large' => UploadFailureReason.tooLarge,
        'too_many' => UploadFailureReason.tooMany,
        _ => UploadFailureReason.typeNotAllowed,
      };
    }
    if (apiError?.code == ErrorCode.network || error is DioException) {
      return UploadFailureReason.network;
    }
    return UploadFailureReason.unknown;
  }

  static Future<void> _delete(String path) async {
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }
}

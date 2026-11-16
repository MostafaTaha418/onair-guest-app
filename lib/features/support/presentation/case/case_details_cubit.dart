import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/support/domain/attachment_draft.dart';
import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/features/support/domain/support_repository.dart';
import 'package:uuid/uuid.dart';

sealed class CaseDetailsState {
  const CaseDetailsState();
}

final class CaseDetailsLoading extends CaseDetailsState {
  const CaseDetailsLoading();
}

final class CaseDetailsNotFound extends CaseDetailsState {
  const CaseDetailsNotFound();
}

final class CaseDetailsFailed extends CaseDetailsState {
  const CaseDetailsFailed(this.error);
  final ApiError error;
}

final class CaseDetailsReady extends CaseDetailsState {
  const CaseDetailsReady({
    required this.details,
    required this.draftId,
    this.body = '',
    this.attachments = const [],
    this.submitting = false,
    this.loadingOlder = false,
  });

  final CaseDetails details;
  final String draftId;
  final String body;
  final List<AttachmentDraft> attachments;
  final bool submitting;
  final bool loadingOlder;

  bool get canSend =>
      !submitting &&
      details.supportCase.status.isReplyable &&
      body.trim().isNotEmpty &&
      attachments.every((attachment) => attachment.state.isUploaded);

  CaseDetailsReady copyWith({
    CaseDetails? details,
    String? draftId,
    String? body,
    List<AttachmentDraft>? attachments,
    bool? submitting,
    bool? loadingOlder,
  }) => CaseDetailsReady(
    details: details ?? this.details,
    draftId: draftId ?? this.draftId,
    body: body ?? this.body,
    attachments: attachments ?? this.attachments,
    submitting: submitting ?? this.submitting,
    loadingOlder: loadingOlder ?? this.loadingOlder,
  );
}

final class CaseDetailsCubit extends Cubit<CaseDetailsState> {
  CaseDetailsCubit({
    required this.caseId,
    required this.repository,
    this.pollInterval = const Duration(seconds: 10),
    this.uuid = const Uuid(),
  }) : super(const CaseDetailsLoading());

  CaseDetailsCubit.seeded({
    required this.caseId,
    required this.repository,
    required CaseDetails details,
    String draftId = 'golden-draft',
  }) : pollInterval = const Duration(seconds: 10),
       uuid = const Uuid(),
       super(CaseDetailsReady(details: details, draftId: draftId));

  final String caseId;
  final SupportRepository repository;
  final Duration pollInterval;
  final Uuid uuid;
  StreamSubscription<void>? _changeSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  Timer? _pollTimer;
  bool _refreshing = false;

  Future<void> load() async {
    _changeSubscription ??= repository
        .caseChanges(caseId)
        .listen((_) => unawaited(refresh()));
    _connectionSubscription ??= repository.liveConnected.listen(
      _setLiveConnected,
    );
    _setLiveConnected(false);
    await refresh(showLoading: true);
  }

  Future<void> refresh({bool showLoading = false}) async {
    if (_refreshing || isClosed) return;
    _refreshing = true;
    final previous = state;
    if (showLoading) emit(const CaseDetailsLoading());
    try {
      final details = await repository.getCase(caseId);
      if (isClosed) return;
      final current = state;
      if (current is CaseDetailsReady) {
        emit(current.copyWith(details: _mergeOptimistic(details, current)));
      } else {
        emit(CaseDetailsReady(details: details, draftId: uuid.v4()));
      }
    } on AppFailure catch (failure) {
      if (isClosed) return;
      if (failure.error.code == ErrorCode.notFound) {
        emit(const CaseDetailsNotFound());
      } else if (previous is! CaseDetailsReady) {
        emit(CaseDetailsFailed(failure.error));
      }
    } finally {
      _refreshing = false;
    }
  }

  void updateBody(String value) {
    final current = state;
    if (current is CaseDetailsReady && !current.submitting) {
      emit(current.copyWith(body: value));
    }
  }

  void updateAttachments(List<AttachmentDraft> value) {
    final current = state;
    if (current is CaseDetailsReady && !current.submitting) {
      emit(current.copyWith(attachments: List.unmodifiable(value)));
    }
  }

  Future<void> send() async {
    final current = state;
    if (current is! CaseDetailsReady || !current.canSend) return;
    final trimmed = current.body.trim();
    final optimistic = CaseMessage(
      id: 'local-${current.draftId}',
      author: MessageAuthor.guest,
      body: trimmed,
      createdAt: DateTime.now().toUtc(),
      attachments: [
        for (final attachment in current.attachments)
          AttachmentRef(
            id: attachment.state.attachmentId!,
            kind: attachment.kind,
            sizeBytes: attachment.sizeBytes,
          ),
      ],
      sendState: MessageSendState.sending,
      draftId: current.draftId,
    );
    emit(
      current.copyWith(
        submitting: true,
        details: current.details.copyWith(
          messages: [...current.details.messages, optimistic],
        ),
      ),
    );
    try {
      final result = await repository.reply(
        caseId,
        ReplyDraft(
          draftId: current.draftId,
          body: trimmed,
          attachmentIds: [
            for (final attachment in current.attachments)
              attachment.state.attachmentId!,
          ],
        ),
      );
      if (isClosed) return;
      final sent = optimistic.copyWith(
        id: result.messageId,
        sendState: MessageSendState.sent,
      );
      emit(
        current.copyWith(
          details: current.details.copyWith(
            supportCase: current.details.supportCase.copyWith(
              status: result.caseStatus,
              lastActivityAt: sent.createdAt,
            ),
            messages: [...current.details.messages, sent],
          ),
          body: '',
          attachments: const [],
          draftId: uuid.v4(),
          submitting: false,
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed) return;
      if (failure.error.code == ErrorCode.notFound) {
        emit(const CaseDetailsNotFound());
      } else if (failure.error.code == ErrorCode.caseClosed) {
        emit(
          current.copyWith(
            details: current.details.copyWith(
              supportCase: current.details.supportCase.copyWith(
                status: CaseStatus.closed,
              ),
            ),
            submitting: false,
          ),
        );
      } else {
        emit(current.copyWith(submitting: false));
      }
    }
  }

  Future<void> loadOlder() async {
    final current = state;
    final cursor = current is CaseDetailsReady
        ? current.details.nextOlderCursor
        : null;
    if (current is! CaseDetailsReady ||
        cursor == null ||
        current.loadingOlder) {
      return;
    }
    emit(current.copyWith(loadingOlder: true));
    try {
      final older = await repository.getCase(caseId, beforeCursor: cursor);
      if (isClosed) return;
      final messages = [...older.messages, ...current.details.messages]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      emit(
        current.copyWith(
          details: current.details.copyWith(
            messages: messages,
            nextOlderCursor: older.nextOlderCursor,
          ),
          loadingOlder: false,
        ),
      );
    } on Object {
      if (!isClosed) emit(current.copyWith(loadingOlder: false));
    }
  }

  CaseDetails _mergeOptimistic(
    CaseDetails incoming,
    CaseDetailsReady current,
  ) {
    final serverDrafts = incoming.messages
        .map((message) => message.draftId)
        .whereType<String>()
        .toSet();
    final pending = current.details.messages.where(
      (message) =>
          message.sendState != MessageSendState.sent &&
          !serverDrafts.contains(message.draftId),
    );
    final messages = [...incoming.messages, ...pending]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return incoming.copyWith(messages: messages);
  }

  void _setLiveConnected(bool connected) {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (!connected && !isClosed) {
      _pollTimer = Timer.periodic(
        pollInterval,
        (_) => unawaited(refresh()),
      );
    }
  }

  @override
  Future<void> close() async {
    _pollTimer?.cancel();
    await _changeSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await repository.closeCaseChanges();
    await super.close();
  }
}

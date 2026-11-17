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
  bool _refreshQueued = false;

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
    if (_refreshing) {
      // A live INSERT landing while a read is in flight must not be
      // dropped: run one more pass once this one settles (the read may
      // have raced the insert on the server).
      if (!isClosed) _refreshQueued = true;
      return;
    }
    if (isClosed) return;
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
      if (_refreshQueued && !isClosed) {
        _refreshQueued = false;
        unawaited(refresh());
      }
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
    final draftId = current.draftId;
    final localId = 'local-$draftId';
    final optimistic = CaseMessage(
      id: localId,
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
      draftId: draftId,
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
          draftId: draftId,
          body: trimmed,
          attachmentIds: [
            for (final attachment in current.attachments)
              attachment.state.attachmentId!,
          ],
        ),
      );
      if (isClosed) return;
      // The conversation may have moved while the reply was in flight
      // (a refresh landed): rebuild on the state on screen now.
      final fresh = state;
      if (fresh is! CaseDetailsReady) return;
      final sent = _promoteSent(fresh, localId, draftId, result);
      emit(
        fresh.copyWith(
          details: fresh.details.copyWith(
            supportCase: fresh.details.supportCase.copyWith(
              status: result.caseStatus,
              lastActivityAt:
                  sent?.createdAt ?? fresh.details.supportCase.lastActivityAt,
            ),
            messages:
                sent == null
                      ? _withoutOptimistic(
                          fresh,
                          localId,
                          draftId,
                          result.messageId,
                        )
                      : [
                          ..._withoutOptimistic(
                            fresh,
                            localId,
                            draftId,
                            result.messageId,
                          ),
                          sent,
                        ]
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
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
        return;
      }
      // Build on the current state, not the copy taken before the await:
      // a refresh during the failed reply must survive.
      final fresh = state;
      if (fresh is CaseDetailsReady) {
        emit(
          fresh.copyWith(
            details: fresh.details.copyWith(
              supportCase: failure.error.code == ErrorCode.caseClosed
                  ? fresh.details.supportCase.copyWith(
                      status: CaseStatus.closed,
                    )
                  : null,
              messages: _withoutOptimistic(fresh, localId, draftId, null),
            ),
            // The typed text, the picked attachments and the draft id all
            // stay, so the retry is idempotent per draft id.
            submitting: false,
          ),
        );
      }
    }
  }

  /// The optimistic row of [draftId], promoted to its server id — or the
  /// server's own echo when a refresh already delivered it.
  CaseMessage? _promoteSent(
    CaseDetailsReady fresh,
    String localId,
    String draftId,
    ReplyResult result,
  ) {
    final local = fresh.details.messages
        .where((message) => message.id == localId)
        .firstOrNull;
    final echoed = fresh.details.messages
        .where((message) => message.draftId == draftId && message.id != localId)
        .firstOrNull;
    return (local ?? echoed)?.copyWith(
      id: result.messageId,
      sendState: MessageSendState.sent,
    );
  }

  /// Every copy of the optimistic row: the local one, a server echo by
  /// message id, and anything sharing the draft id.
  List<CaseMessage> _withoutOptimistic(
    CaseDetailsReady fresh,
    String localId,
    String draftId,
    String? messageId,
  ) => fresh.details.messages
      .where(
        (message) =>
            message.id != localId &&
            message.draftId != draftId &&
            message.id != messageId,
      )
      .toList();

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
      // A refresh may have landed while the older page was in flight:
      // merge with the state on screen now.
      final fresh = state;
      if (fresh is! CaseDetailsReady) return;
      final seen = <String>{};
      final messages = [
        for (final message in [...older.messages, ...fresh.details.messages])
          if (seen.add(message.id)) message,
      ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      emit(
        fresh.copyWith(
          details: fresh.details.copyWith(
            messages: messages,
            nextOlderCursor: older.nextOlderCursor,
          ),
          loadingOlder: false,
        ),
      );
    } on Object {
      final fresh = state;
      if (!isClosed && fresh is CaseDetailsReady) {
        emit(fresh.copyWith(loadingOlder: false));
      }
    }
  }

  CaseDetails _mergeOptimistic(
    CaseDetails incoming,
    CaseDetailsReady current,
  ) {
    final serverIds = incoming.messages.map((message) => message.id).toSet();
    final serverDrafts = incoming.messages
        .map((message) => message.draftId)
        .whereType<String>()
        .toSet();
    // The server page wins for its own rows and for optimistic rows it
    // echoed back by draft id. Everything else already in memory —
    // in-flight optimistic rows and older pages loaded above the newest
    // one — survives the refresh.
    final kept = current.details.messages.where(
      (message) =>
          !serverIds.contains(message.id) &&
          (message.sendState == MessageSendState.sent ||
              !serverDrafts.contains(message.draftId)),
    );
    final messages = [...kept, ...incoming.messages]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    // The oldest loaded page is still on screen: keep its cursor, or the
    // scroll-up pagination would jump back to the newest page.
    return incoming.copyWith(
      messages: messages,
      nextOlderCursor: current.details.nextOlderCursor,
    );
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

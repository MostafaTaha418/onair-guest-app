import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/support/domain/attachment_draft.dart';
import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/features/support/domain/support_repository.dart';
import 'package:uuid/uuid.dart';

sealed class NewCaseState {
  const NewCaseState();
}

final class NewCaseReady extends NewCaseState {
  const NewCaseReady({
    required this.draftId,
    this.type,
    this.bookingId,
    this.bookingCode,
    this.propertyId,
    this.propertyTitle,
    this.body = '',
    this.attachments = const [],
    this.submitting = false,
    this.online = true,
    this.error,
  });

  final String draftId;
  final CaseType? type;
  final String? bookingId;
  final String? bookingCode;
  final String? propertyId;
  final String? propertyTitle;
  final String body;
  final List<AttachmentDraft> attachments;
  final bool submitting;
  final bool online;
  final ApiError? error;

  /// Leaving with content asks before discarding (US2-7): text or files.
  bool get hasContent => body.trim().isNotEmpty || attachments.isNotEmpty;

  /// data-model §3: a valid body and a chosen type, every attachment
  /// uploaded, not already submitting, and online.
  bool get canSend =>
      online &&
      !submitting &&
      type != null &&
      body.trim().length >= 10 &&
      body.trim().length <= 4000 &&
      attachments.every((attachment) => attachment.state.isUploaded);

  NewCaseReady copyWith({
    CaseType? type,
    bool clearType = false,
    String? body,
    List<AttachmentDraft>? attachments,
    String? bookingCode,
    String? propertyTitle,
    bool? submitting,
    bool? online,
    ApiError? error,
    bool clearError = false,
  }) => NewCaseReady(
    draftId: draftId,
    type: clearType ? null : type ?? this.type,
    bookingId: bookingId,
    bookingCode: bookingCode ?? this.bookingCode,
    propertyId: propertyId,
    propertyTitle: propertyTitle ?? this.propertyTitle,
    body: body ?? this.body,
    attachments: attachments ?? this.attachments,
    submitting: submitting ?? this.submitting,
    online: online ?? this.online,
    error: clearError ? null : error ?? this.error,
  );
}

final class NewCaseCreated extends NewCaseState {
  const NewCaseCreated({required this.caseId, required this.code});

  final String caseId;
  final String code;
}

final class NewCaseCubit extends Cubit<NewCaseState> {
  NewCaseCubit({
    required this.repository,
    this.bookings,
    this.resolvePropertyTitle,
    ConnectivityCubit? connection,
    Uuid uuid = const Uuid(),
  }) : uuid = uuid,
       super(NewCaseReady(draftId: uuid.v4())) {
    if (connection != null) {
      _setOnline(connection.state.isOnline);
      _connectivitySubscription = connection.stream.listen(
        (status) => _setOnline(status.isOnline),
      );
    }
  }

  /// Starts from a fully formed state; goldens and previews only.
  NewCaseCubit.seeded({
    required this.repository,
    required NewCaseReady state,
  }) : bookings = null,
       resolvePropertyTitle = null,
       uuid = const Uuid(),
       super(state);

  final SupportRepository repository;
  final BookingsRepository? bookings;

  /// Best-effort lookup of the linked apartment's display title; null when
  /// the caller has no listings source.
  final Future<String?> Function(String propertyId)? resolvePropertyTitle;
  final Uuid uuid;
  StreamSubscription<ConnectivityState>? _connectivitySubscription;
  bool _opened = false;

  static final _uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// Applies the entry-point parameters once; invalid values are ignored.
  void open({String? bookingId, String? propertyId, String? type}) {
    if (_opened) return;
    _opened = true;
    final current = state as NewCaseReady;
    final linkedBooking = _isUuidV4(bookingId) ? bookingId : null;
    final linkedProperty = _isUuidV4(propertyId) ? propertyId : null;
    final chosenType = CaseType.guestSelectable
        .where((candidate) => candidate.raw == type)
        .firstOrNull;
    // FR-007: the entry point preselects a fitting type.
    final preselected =
        chosenType ??
        (linkedBooking != null
            ? CaseType.booking
            : linkedProperty != null
            ? CaseType.other
            : null);
    emit(
      NewCaseReady(
        draftId: current.draftId,
        type: preselected,
        bookingId: linkedBooking,
        propertyId: linkedProperty,
        online: current.online,
      ),
    );
    if (linkedBooking != null) unawaited(_resolveBookingCode(linkedBooking));
    if (linkedProperty != null) {
      unawaited(_resolvePropertyTitle(linkedProperty));
    }
  }

  void updateType(CaseType? value) {
    final current = state;
    if (current is! NewCaseReady || current.submitting) return;
    emit(current.copyWith(type: value, clearType: value == null));
  }

  void updateBody(String value) {
    final current = state;
    if (current is! NewCaseReady || current.submitting) return;
    emit(current.copyWith(body: value));
  }

  void updateAttachments(List<AttachmentDraft> value) {
    final current = state;
    if (current is! NewCaseReady || current.submitting) return;
    emit(current.copyWith(attachments: List.unmodifiable(value)));
  }

  void linkBooking(BookingSummary summary) {
    final current = state;
    if (current is! NewCaseReady || current.submitting) return;
    emit(
      NewCaseReady(
        draftId: current.draftId,
        type: current.type,
        body: current.body,
        attachments: current.attachments,
        bookingId: summary.id,
        bookingCode: summary.code,
        online: current.online,
        error: current.error,
      ),
    );
  }

  /// Removes the booking/apartment link; the chosen type and the rest of the
  /// draft stay as they were.
  void unlink() {
    final current = state;
    if (current is! NewCaseReady || current.submitting) return;
    emit(
      NewCaseReady(
        draftId: current.draftId,
        type: current.type,
        body: current.body,
        attachments: current.attachments,
        online: current.online,
        error: current.error,
      ),
    );
  }

  Future<void> submit() async {
    final current = state;
    if (current is! NewCaseReady || !current.canSend) return;
    emit(current.copyWith(submitting: true, clearError: true));
    try {
      final created = await repository.createCase(
        NewCaseDraft(
          draftId: current.draftId,
          type: current.type!,
          body: current.body.trim(),
          bookingId: current.bookingId,
          propertyId: current.propertyId,
          attachmentIds: [
            for (final attachment in current.attachments)
              attachment.state.attachmentId!,
          ],
        ),
      );
      if (!isClosed) {
        emit(NewCaseCreated(caseId: created.caseId, code: created.code));
      }
    } on AppFailure catch (failure) {
      // The same draft id is kept so a retry cannot create a second case
      // (FR-009).
      if (!isClosed) {
        emit(current.copyWith(submitting: false, error: failure.error));
      }
    }
  }

  void acknowledgeError() {
    final current = state;
    if (current is NewCaseReady && current.error != null) {
      emit(current.copyWith(clearError: true));
    }
  }

  Future<void> _resolveBookingCode(String bookingId) async {
    final bookings = this.bookings;
    if (bookings == null) return;
    try {
      final details = await bookings.getBooking(bookingId);
      final current = state;
      if (!isClosed &&
          current is NewCaseReady &&
          current.bookingId == bookingId) {
        emit(current.copyWith(bookingCode: details.code));
      }
    } on Object {
      // The link stays; the chip falls back to the booking id.
    }
  }

  Future<void> _resolvePropertyTitle(String propertyId) async {
    final resolve = resolvePropertyTitle;
    if (resolve == null) return;
    try {
      final title = await resolve(propertyId);
      final current = state;
      if (!isClosed &&
          title != null &&
          current is NewCaseReady &&
          current.propertyId == propertyId) {
        emit(current.copyWith(propertyTitle: title));
      }
    } on Object {
      // The link stays; the chip falls back to the property id.
    }
  }

  void _setOnline(bool online) {
    final current = state;
    if (current is NewCaseReady && current.online != online) {
      emit(current.copyWith(online: online));
    }
  }

  bool _isUuidV4(String? value) => value != null && _uuidV4.hasMatch(value);

  @override
  Future<void> close() async {
    await _connectivitySubscription?.cancel();
    await super.close();
  }
}

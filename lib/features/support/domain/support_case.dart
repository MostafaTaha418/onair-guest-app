import 'package:flutter/foundation.dart';
import 'package:on_air/core/files/upload_limits.dart';

@immutable
final class CaseType {
  const CaseType._(this.raw, this.isUnknown);

  factory CaseType.fromWire(String raw) => switch (raw) {
    'booking' => booking,
    'payment' => payment,
    'refund' => refund,
    'property_issue' => propertyIssue,
    'other' => other,
    'damage_dispute' => damageDispute,
    'complaint' => complaint,
    'stay_exception' => stayException,
    _ => CaseType._(raw, true),
  };

  static const booking = CaseType._('booking', false);
  static const payment = CaseType._('payment', false);
  static const refund = CaseType._('refund', false);
  static const propertyIssue = CaseType._('property_issue', false);
  static const other = CaseType._('other', false);
  static const damageDispute = CaseType._('damage_dispute', false);
  static const complaint = CaseType._('complaint', false);
  static const stayException = CaseType._('stay_exception', false);

  static const List<CaseType> guestSelectable = [
    booking,
    payment,
    refund,
    propertyIssue,
    other,
  ];

  final String raw;
  final bool isUnknown;

  @override
  bool operator ==(Object other) =>
      other is CaseType && other.raw == raw && other.isUnknown == isUnknown;

  @override
  int get hashCode => Object.hash(raw, isUnknown);
}

@immutable
final class CaseStatus {
  const CaseStatus._(this.raw, this.isUnknown);

  factory CaseStatus.fromWire(String raw) => switch (raw) {
    'open' => open,
    'in_progress' => inProgress,
    'waiting_user' => waitingUser,
    'resolved' => resolved,
    'closed' => closed,
    _ => CaseStatus._(raw, true),
  };

  static const open = CaseStatus._('open', false);
  static const inProgress = CaseStatus._('in_progress', false);
  static const waitingUser = CaseStatus._('waiting_user', false);
  static const resolved = CaseStatus._('resolved', false);
  static const closed = CaseStatus._('closed', false);

  final String raw;
  final bool isUnknown;

  bool get isOpen => this == open || this == inProgress || this == waitingUser;
  bool get isReplyable => this != closed;

  @override
  bool operator ==(Object other) =>
      other is CaseStatus && other.raw == raw && other.isUnknown == isUnknown;

  @override
  int get hashCode => Object.hash(raw, isUnknown);
}

@immutable
final class SupportCase {
  const SupportCase({
    required this.id,
    required this.code,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.lastActivityAt,
    required this.hasUnreadStaffReply,
    this.bookingId,
    this.bookingCode,
    this.propertyId,
    this.propertyTitle,
  });

  factory SupportCase.fromJson(Map<String, dynamic> json) => SupportCase(
    id: json['id'] as String,
    code: json['code'] as String,
    type: CaseType.fromWire(json['type'] as String),
    status: CaseStatus.fromWire(json['status'] as String),
    bookingId: json['booking_id'] as String?,
    bookingCode: json['booking_code'] as String?,
    propertyId: json['property_id'] as String?,
    propertyTitle: json['property_title'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    lastActivityAt: DateTime.parse(
      json['last_activity_at'] as String,
    ).toUtc(),
    hasUnreadStaffReply: json['has_unread_staff_reply'] as bool? ?? false,
  );

  final String id;
  final String code;
  final CaseType type;
  final CaseStatus status;
  final String? bookingId;
  final String? bookingCode;
  final String? propertyId;
  final String? propertyTitle;
  final DateTime createdAt;
  final DateTime lastActivityAt;
  final bool hasUnreadStaffReply;

  SupportCase copyWith({
    CaseStatus? status,
    DateTime? lastActivityAt,
    bool? hasUnreadStaffReply,
  }) => SupportCase(
    id: id,
    code: code,
    type: type,
    status: status ?? this.status,
    bookingId: bookingId,
    bookingCode: bookingCode,
    propertyId: propertyId,
    propertyTitle: propertyTitle,
    createdAt: createdAt,
    lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    hasUnreadStaffReply: hasUnreadStaffReply ?? this.hasUnreadStaffReply,
  );

  static int compareForList(SupportCase a, SupportCase b) {
    if (a.status.isOpen != b.status.isOpen) return a.status.isOpen ? -1 : 1;
    final byActivity = b.lastActivityAt.compareTo(a.lastActivityAt);
    return byActivity != 0 ? byActivity : a.id.compareTo(b.id);
  }

  @override
  bool operator ==(Object other) =>
      other is SupportCase &&
      other.id == id &&
      other.code == code &&
      other.type == type &&
      other.status == status &&
      other.bookingId == bookingId &&
      other.bookingCode == bookingCode &&
      other.propertyId == propertyId &&
      other.propertyTitle == propertyTitle &&
      other.createdAt == createdAt &&
      other.lastActivityAt == lastActivityAt &&
      other.hasUnreadStaffReply == hasUnreadStaffReply;

  @override
  int get hashCode => Object.hash(
    id,
    code,
    type,
    status,
    bookingId,
    bookingCode,
    propertyId,
    propertyTitle,
    createdAt,
    lastActivityAt,
    hasUnreadStaffReply,
  );
}

@immutable
final class CasePage {
  const CasePage({required this.items, required this.nextCursor});

  factory CasePage.fromJson(Map<String, dynamic> json) => CasePage(
    items: [
      for (final item in json['items'] as List? ?? const [])
        SupportCase.fromJson(Map<String, dynamic>.from(item as Map)),
    ]..sort(SupportCase.compareForList),
    nextCursor: json['next_cursor'] as String?,
  );

  final List<SupportCase> items;
  final String? nextCursor;
}

enum MessageAuthor { guest, onAir }

enum MessageSendState { sent, sending, failed }

@immutable
final class AttachmentRef {
  const AttachmentRef({
    required this.id,
    required this.kind,
    required this.sizeBytes,
    this.width,
    this.height,
  });

  factory AttachmentRef.fromJson(Map<String, dynamic> json) => AttachmentRef(
    id: json['id'] as String,
    kind: switch (json['kind']) {
      'pdf' => AttachmentKind.pdf,
      _ => AttachmentKind.image,
    },
    sizeBytes: (json['size_bytes'] as num).toInt(),
    width: (json['width'] as num?)?.toInt(),
    height: (json['height'] as num?)?.toInt(),
  );

  final String id;
  final AttachmentKind kind;
  final int sizeBytes;
  final int? width;
  final int? height;
}

@immutable
final class CaseMessage {
  const CaseMessage({
    required this.id,
    required this.author,
    required this.body,
    required this.createdAt,
    required this.attachments,
    this.sendState = MessageSendState.sent,
    this.draftId,
  });

  factory CaseMessage.fromJson(Map<String, dynamic> json) => CaseMessage(
    id: json['id'] as String,
    author: json['author'] == 'guest'
        ? MessageAuthor.guest
        : MessageAuthor.onAir,
    body: json['body'] as String,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    attachments: [
      for (final item in json['attachments'] as List? ?? const [])
        AttachmentRef.fromJson(Map<String, dynamic>.from(item as Map)),
    ],
  );

  final String id;
  final MessageAuthor author;
  final String body;
  final DateTime createdAt;
  final List<AttachmentRef> attachments;
  final MessageSendState sendState;
  final String? draftId;

  CaseMessage copyWith({
    String? id,
    MessageSendState? sendState,
  }) => CaseMessage(
    id: id ?? this.id,
    author: author,
    body: body,
    createdAt: createdAt,
    attachments: attachments,
    sendState: sendState ?? this.sendState,
    draftId: draftId,
  );
}

@immutable
final class CaseDetails {
  const CaseDetails({
    required this.supportCase,
    required this.messages,
    required this.nextOlderCursor,
  });

  factory CaseDetails.fromJson(Map<String, dynamic> json) {
    final messages = [
      for (final item in json['messages'] as List? ?? const [])
        CaseMessage.fromJson(Map<String, dynamic>.from(item as Map)),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return CaseDetails(
      supportCase: SupportCase.fromJson(
        Map<String, dynamic>.from(json['case'] as Map),
      ),
      messages: messages,
      nextOlderCursor: json['next_older_cursor'] as String?,
    );
  }

  final SupportCase supportCase;
  final List<CaseMessage> messages;
  final String? nextOlderCursor;

  CaseDetails copyWith({
    SupportCase? supportCase,
    List<CaseMessage>? messages,
    String? nextOlderCursor,
  }) => CaseDetails(
    supportCase: supportCase ?? this.supportCase,
    messages: messages ?? this.messages,
    nextOlderCursor: nextOlderCursor ?? this.nextOlderCursor,
  );
}

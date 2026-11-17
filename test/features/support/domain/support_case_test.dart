import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/files/upload_limits.dart';
import 'package:on_air/features/support/domain/support_case.dart';

void main() {
  const caseId = 'c0000000-0000-4000-8000-000000000001';
  final json = <String, dynamic>{
    'id': caseId,
    'code': 'SC-1042',
    'type': 'booking',
    'status': 'waiting_user',
    'booking_id': 'b0000000-0000-4000-8000-000000000001',
    'booking_code': 'OA-1042',
    'property_id': 'p0000000-0000-4000-8000-000000000001',
    'property_title': 'شقة البحر',
    'created_at': '2026-11-10T10:00:00Z',
    'last_activity_at': '2026-11-11T10:00:00Z',
    'has_unread_staff_reply': true,
  };

  test('SupportCase maps the complete U1 list item', () {
    final supportCase = SupportCase.fromJson(json);
    expect(supportCase.id, caseId);
    expect(supportCase.code, 'SC-1042');
    expect(supportCase.type, CaseType.booking);
    expect(supportCase.status, CaseStatus.waitingUser);
    expect(supportCase.bookingCode, 'OA-1042');
    expect(supportCase.propertyTitle, 'شقة البحر');
    expect(supportCase.hasUnreadStaffReply, isTrue);
    expect(supportCase.createdAt.isUtc, isTrue);
  });

  test('unknown type and status preserve their raw server values', () {
    expect(CaseType.fromWire('future_type').raw, 'future_type');
    expect(CaseType.fromWire('future_type').isUnknown, isTrue);
    expect(CaseStatus.fromWire('future_status').raw, 'future_status');
    expect(CaseStatus.fromWire('future_status').isUnknown, isTrue);
  });

  test('open and replyable flags follow the contract', () {
    expect(
      [
        CaseStatus.open,
        CaseStatus.inProgress,
        CaseStatus.waitingUser,
      ].every((status) => status.isOpen),
      isTrue,
    );
    expect(CaseStatus.resolved.isOpen, isFalse);
    expect(CaseStatus.closed.isReplyable, isFalse);
    expect(CaseStatus.resolved.isReplyable, isTrue);
  });

  test('sort puts open cases first then newest activity', () {
    SupportCase item(String id, CaseStatus status, int day) =>
        SupportCase.fromJson({
          ...json,
          'id': id,
          'status': status.raw,
          'last_activity_at':
              '2026-11-${day.toString().padLeft(2, '0')}T10:00:00Z',
        });
    final items = [
      item('c0000000-0000-4000-8000-000000000002', CaseStatus.closed, 15),
      item('c0000000-0000-4000-8000-000000000003', CaseStatus.open, 12),
      item('c0000000-0000-4000-8000-000000000004', CaseStatus.resolved, 14),
      item('c0000000-0000-4000-8000-000000000005', CaseStatus.waitingUser, 13),
    ]..sort(SupportCase.compareForList);
    expect(items.map((item) => item.id), [
      'c0000000-0000-4000-8000-000000000005',
      'c0000000-0000-4000-8000-000000000003',
      'c0000000-0000-4000-8000-000000000002',
      'c0000000-0000-4000-8000-000000000004',
    ]);
  });

  test('message maps authors and attachment metadata', () {
    final message = CaseMessage.fromJson(const {
      'id': 'm1',
      'author': 'onair',
      'body': 'رد OnAir',
      'created_at': '2026-11-11T11:00:00Z',
      'attachments': [
        {
          'id': 'a1',
          'kind': 'image',
          'size_bytes': 1024,
          'width': 800,
          'height': 600,
        },
        {'id': 'a2', 'kind': 'pdf', 'size_bytes': 2048},
      ],
    });
    expect(message.author, MessageAuthor.onAir);
    expect(message.attachments.first.kind, AttachmentKind.image);
    expect(message.attachments.first.width, 800);
    expect(message.attachments.last.kind, AttachmentKind.pdf);
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_air/features/support/data/mock_support_server.dart';
import 'package:on_air/features/support/domain/support_case.dart';

Future<void> showMockSupportToolsSheet(
  BuildContext context, {
  required MockSupportServer server,
  required String caseId,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.support_agent),
          title: const Text('رد من OnAir'),
          onTap: () {
            Navigator.pop(context);
            unawaited(Future<void>(() => server.sendStaffReply(caseId)));
          },
        ),
        ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: const Text('اتحلّت'),
          onTap: () {
            server.setStatus(caseId, CaseStatus.resolved);
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('اتقفلت'),
          onTap: () {
            server.setStatus(caseId, CaseStatus.closed);
            Navigator.pop(context);
          },
        ),
      ],
    ),
  ),
);

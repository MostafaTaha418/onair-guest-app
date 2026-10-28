import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/router/incoming_links.dart';

import '../test_app_harness.dart';

final class _FakeUriLinkSource implements UriLinkSource {
  final controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get uriLinks => controller.stream;
}

void main() {
  testWidgets(
    'incoming verified links navigate through the parser and router',
    (
      tester,
    ) async {
      final source = _FakeUriLinkSource();
      addTearDown(source.controller.close);
      await pumpVisitorAppWithLinks(
        tester,
        uriLinkSource: source,
        linkDomain: 'on-air.website',
      );

      source.controller.add(
        Uri.parse(
          'https://on-air.website/property/'
          '550e8400-e29b-41d4-a716-446655440000?status=paid',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('غير متاح حاليًا'), findsOneWidget);
    },
  );
}

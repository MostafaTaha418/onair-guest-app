import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/router/incoming_links.dart';
import 'package:on_air/features/property/presentation/property_screen.dart';

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

      // Since US2 the link opens the real details screen (the fake
      // repository answers with its default published apartment). The
      // 4:3 gallery header fills the default test viewport, so assert on
      // the screen and its bottom bar. A link whose ID is unknown still
      // lands on the not-available content (covered in
      // test/features/property/property_screen_test.dart).
      expect(find.byType(PropertyScreen), findsOneWidget);
      expect(find.text('EGP 1,000.00 / الليلة'), findsOneWidget);
    },
  );
}

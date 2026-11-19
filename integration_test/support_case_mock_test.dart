import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_air/core/files/attachment_picker.dart';
import 'package:on_air/design_system/components/attachment_tile.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/features/support/data/mock_support_server.dart';
import 'package:on_air/features/support/presentation/case/case_details_screen.dart';
import 'package:on_air/features/support/presentation/new_case/new_case_screen.dart';
import 'package:on_air/features/support/presentation/widgets/reply_composer.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../test/helpers/booking_journey.dart';
import '../test/helpers/fake_attachment_picker.dart';
import '../test/helpers/mock_app.dart';
import '../test/helpers/pump_until_found.dart';

/// T055 (US1 + US2): the full basic support loop on a device runner —
/// booking details → «تواصل مع OnAir» → 2 photos → double-tap send → one
/// case; the mock staff reply arrives; the tools resolve the case; a guest
/// reply reopens it; closing it offers «افتح حالة جديدة» pre-linking the
/// booking. Mock mode only (BACKEND_MODE=mock).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final l10n = lookupAppLocalizations(const Locale('ar'));

  /// Two real decodable images, so the app pipeline (sanitize → sign →
  /// PUT) runs exactly as it does for a guest.
  Future<List<PickedFile>> twoPhotos() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 32, 32),
      Paint()..color = const Color(0xFF006399),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(32, 32);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final directory = await Directory.systemTemp.createTemp('on_air_photos');
    addTearDown(() => directory.deleteSync(recursive: true));
    final files = <PickedFile>[];
    for (var index = 0; index < 2; index++) {
      final path = '${directory.path}/photo-$index.png';
      await File(path).writeAsBytes(bytes.buffer.asUint8List());
      files.add(
        PickedFile(
          path: path,
          name: 'photo-$index.png',
          sizeBytes: bytes.lengthInBytes,
          mime: 'image/png',
        ),
      );
    }
    return files;
  }

  Future<void> pickTwoPhotos(WidgetTester tester) async {
    await pumpUntilFound(tester, find.text(l10n.supportAttach));
    await tester.tap(find.text(l10n.supportAttach));
    await pumpUntilFound(tester, find.text(l10n.supportAttachGallery));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text(l10n.supportAttachGallery));
    await pumpUntilCount(tester, find.byType(AttachmentTile), 2);
    // The fake signer and PUT finish in a couple of frames; the tiles must
    // be uploaded («ready») before «إرسال» is allowed.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('the full support loop from a booking', (tester) async {
    final picker = FakeAttachmentPicker();
    final photos = await twoPhotos();
    final server = MockSupportServer(latency: Duration.zero);
    picker.gallery = photos;
    await bootMockApp(tester, support: server, attachmentPicker: picker);

    // 1. Create and pay for a booking, then land on its details screen.
    await openFirstApartmentAndSignIn(tester, l10n, firstSignIn: true);
    await pickThreeNights(tester, l10n);
    await tester.tap(find.byKey(const ValueKey('dates-continue')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('summary-pay')));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('summary-pay')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('mock-pay-success')),
    );
    await tester.tap(find.byKey(const ValueKey('mock-pay-success')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await pumpUntilFound(tester, find.text(l10n.paymentSuccessTitle));
    await tester.pump(const Duration(seconds: 1));
    await tapAndWait(
      tester,
      find.byKey(const ValueKey('return-view-booking')),
      find.text(l10n.bookingContactSupport),
    );

    // 2. «تواصل مع OnAir» → the form opens with the booking linked and
    //    «حجز» preselected (FR-007).
    await tester.pump(const Duration(seconds: 1));
    await tapAndWait(
      tester,
      find.text(l10n.bookingContactSupport),
      find.byType(NewCaseScreen),
    );
    await pumpUntilFound(
      tester,
      find.text(l10n.supportLinkedBooking('OA-MOCK001')),
    );
    final bookingChip = tester.widget<ChoiceChip>(
      find.byType(ChoiceChip).first,
    );
    expect((bookingChip.label as Text?)?.data, l10n.supportTypeBooking);
    expect(bookingChip.selected, isTrue);

    // 3. Two photos through the real pick → sanitize → upload pipeline.
    await pickTwoPhotos(tester);

    // 4. Write the description and double-tap send: exactly one case.
    await tester.enterText(
      find.byType(TextField),
      'المكيف مش شغال وصورته للحالة',
    );
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    // «إرسال» only enables once the fake sign + PUT pipeline marks both
    // attachments ready. A slower device runner needs more than the fixed
    // pumps in pickTwoPhotos, so wait for the button to actually enable.
    final send = find.widgetWithText(OnAirPrimaryButton, l10n.supportSend);
    await pumpUntilFound(tester, send);
    for (var attempt = 0; attempt < 80; attempt++) {
      if (tester.widget<OnAirPrimaryButton>(send).onPressed != null) break;
      await tester.pump(const Duration(milliseconds: 250));
    }
    // A rapid double-tap must still create exactly one case (RapidSubmitGuard);
    // on a device the first tap can already be navigating away, so only repeat
    // it while the button is still mounted.
    await tester.tap(send);
    if (tester.any(send)) await tester.tap(send, warnIfMissed: false);
    await pumpUntilFound(tester, find.byType(CaseDetailsScreen));
    await pumpUntilFound(tester, find.text('SC-1043'));
    expect(server.createCalls, 1);

    // 5. The mock staff reply arrives within seconds.
    await pumpUntilFound(
      tester,
      find.text('وصلنا ردك، وفريق OnAir بيتابع معاك.'),
      maxAttempts: 200,
    );

    // 6. The tools mark the case resolved; the notice appears.
    await tester.longPress(find.text('SC-1043'));
    await pumpUntilFound(tester, find.text('اتحلّت'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('اتحلّت'));
    await pumpUntilFound(tester, find.text(l10n.supportResolvedNotice));

    // 7. Replying reopens the case («مفتوحة»).
    await tester.enterText(
      find.descendant(
        of: find.byType(ReplyComposer),
        matching: find.byType(TextField),
      ),
      'لسه محتاج مساعدة',
    );
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await pumpUntilFound(tester, find.text(l10n.supportStatusOpen));

    // 8. Closing it offers «افتح حالة جديدة», pre-linking the booking.
    await tester.longPress(find.text('SC-1043'));
    await pumpUntilFound(tester, find.text('اتقفلت'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('اتقفلت'));
    await pumpUntilFound(tester, find.text(l10n.supportCaseClosed));
    await tester.pump(const Duration(seconds: 1));
    await tapAndWait(
      tester,
      find.text(l10n.supportOpenNewCase),
      find.byType(NewCaseScreen),
    );
    await pumpUntilFound(
      tester,
      find.text(l10n.supportLinkedBooking('OA-MOCK001')),
    );
    final reopenedChip = tester.widget<ChoiceChip>(
      find.byType(ChoiceChip).first,
    );
    expect((reopenedChip.label as Text?)?.data, l10n.supportTypeBooking);
    expect(reopenedChip.selected, isTrue);
    // The journey only reached a created case; nothing else leaked in.
    expect(server.createdCount, 1);
    expect(server.createCalls, 1);
  });
}

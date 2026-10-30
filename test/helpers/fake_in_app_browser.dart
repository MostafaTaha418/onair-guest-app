import 'package:on_air/core/payments/in_app_browser.dart';

/// Records every opened URL; never touches a platform channel.
final class FakeInAppBrowser implements InAppBrowser {
  final List<({Uri url, String bookingId})> opened = [];

  @override
  Future<void> open(Uri url, {required String bookingId}) async {
    opened.add((url: url, bookingId: bookingId));
  }
}

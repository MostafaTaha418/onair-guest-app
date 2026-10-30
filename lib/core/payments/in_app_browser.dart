import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the Kashier page (research R4): Chrome Custom Tabs on Android,
/// SFSafariViewController on iOS — never a WebView (Constitution III).
abstract interface class InAppBrowser {
  Future<void> open(Uri url, {required String bookingId});
}

final class UrlLauncherInAppBrowser implements InAppBrowser {
  const UrlLauncherInAppBrowser();

  @override
  Future<void> open(Uri url, {required String bookingId}) async {
    if (await launchUrl(url, mode: LaunchMode.inAppBrowserView)) {
      return;
    }
    // Some devices have no in-app browser provider; fall back once to the
    // external browser before giving up.
    if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
      return;
    }
    throw AppFailure(ErrorMapper.fromCode('INTERNAL'));
  }
}

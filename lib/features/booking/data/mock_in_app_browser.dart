import 'package:flutter/material.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/payments/in_app_browser.dart';
import 'package:on_air/features/booking/presentation/mock_payment_page.dart';
import 'package:on_air/features/bookings/data/mock_booking_server.dart';

/// Mock-mode browser: instead of leaving the app it pushes a local page
/// with Succeed / Fail / Cancel / Close buttons (quickstart, mock mode).
final class MockInAppBrowser implements InAppBrowser {
  MockInAppBrowser({
    required this._navigatorKey,
    required this._server,
    required this._onReturn,
  });

  final GlobalKey<NavigatorState> _navigatorKey;
  final MockBookingServer _server;
  final void Function(String bookingId) _onReturn;

  @override
  Future<void> open(Uri url, {required String bookingId}) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      throw AppFailure(ErrorMapper.fromCode('INTERNAL'));
    }
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => MockPaymentPage(
          bookingId: bookingId,
          server: _server,
          onReturn: _onReturn,
        ),
      ),
    );
  }
}

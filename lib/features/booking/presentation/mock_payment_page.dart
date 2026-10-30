import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/features/bookings/data/mock_booking_server.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The mock payment page (mock mode only): stands in for the Kashier page
/// so the whole journey runs without a network.
final class MockPaymentPage extends StatelessWidget {
  const MockPaymentPage({
    required this.bookingId,
    required this.server,
    required this.onReturn,
    super.key,
  });

  final String bookingId;
  final MockBookingServer server;
  final void Function(String bookingId) onReturn;

  void _complete(BuildContext context, MockPaymentResult result) {
    unawaited(
      server.completePayment(
        bookingId,
        result,
        signalDelay: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
    onReturn(bookingId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mockPaymentTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            children: [
              OnAirPrimaryButton(
                key: const ValueKey('mock-pay-success'),
                label: l10n.mockPaySuccess,
                onPressed: () => _complete(context, MockPaymentResult.success),
              ),
              const SizedBox(height: 12),
              OnAirPrimaryButton(
                key: const ValueKey('mock-pay-failure'),
                label: l10n.mockPayFailure,
                onPressed: () => _complete(context, MockPaymentResult.failure),
              ),
              const SizedBox(height: 12),
              OnAirPrimaryButton(
                key: const ValueKey('mock-pay-conflict'),
                label: l10n.mockPayConflict,
                onPressed: () => _complete(context, MockPaymentResult.conflict),
              ),
              const SizedBox(height: 12),
              OnAirPrimaryButton(
                key: const ValueKey('mock-pay-silent'),
                label: l10n.mockPaySilent,
                onPressed: () => _complete(context, MockPaymentResult.silent),
              ),
              const SizedBox(height: 12),
              OnAirPrimaryButton(
                key: const ValueKey('mock-pay-close'),
                label: l10n.mockPayClose,
                onPressed: () => _complete(context, MockPaymentResult.failure),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

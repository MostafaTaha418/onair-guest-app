import 'package:flutter/foundation.dart';

/// Staging-only bridge for the OTP «echo» code.
///
/// The Meta test number cannot create an authentication template, so the
/// staging Worker runs with `OTP_ECHO=1` and returns the code in the send
/// response (`echo_code`) instead of sending it over WhatsApp. In debug builds
/// the `OtpSendInterceptor` captures it here so the WhatsApp code step can show
/// it, letting phone verification / change be tested without a production
/// number.
///
/// It is never populated in production: the production Worker never returns
/// `echo_code`, and the capture is guarded by `kDebugMode`.
final ValueNotifier<String?> otpEchoCode = ValueNotifier<String?>(null);

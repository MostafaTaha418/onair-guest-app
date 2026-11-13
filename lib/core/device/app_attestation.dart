import 'package:firebase_app_check/firebase_app_check.dart';

/// A limited-use App Check token for `POST /v1/otp/send` (research R3).
/// The token is memory-only and never logged (Constitution IV).
abstract interface class AppAttestation {
  Future<String?> limitedUseToken();
}

final class FirebaseAppAttestation implements AppAttestation {
  const FirebaseAppAttestation();

  @override
  Future<String?> limitedUseToken() async {
    try {
      return await FirebaseAppCheck.instance.getLimitedUseToken();
    } on Object {
      // A missing/failed attestation never blocks the request: the server
      // answers APP_ATTESTATION_FAILED with its own message (R3).
      return null;
    }
  }
}

/// Mock mode and tests: no attestation at all.
final class NoAttestation implements AppAttestation {
  const NoAttestation();

  @override
  Future<String?> limitedUseToken() async => null;
}

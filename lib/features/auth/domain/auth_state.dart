import 'package:on_air/features/auth/domain/guest_account.dart';

enum VerificationChannel { sms, emailSignup, emailRecovery }

final class CodeChallenge {
  const CodeChallenge({
    required this.channel,
    required this.target,
    required this.resendAt,
  });

  final VerificationChannel channel;
  final String target;
  final DateTime resendAt;
}

sealed class AuthState {
  const AuthState();
}

final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

final class SignedOut extends AuthState {
  const SignedOut();
}

final class CodeSent extends AuthState {
  const CodeSent(this.challenge, {this.errorCode});

  final CodeChallenge challenge;
  final String? errorCode;
}

final class RateLimited extends AuthState {
  const RateLimited(this.challenge, this.until);

  final CodeChallenge challenge;
  final DateTime until;
}

final class SignedIn extends AuthState {
  const SignedIn(this.account, {required this.isComplete});

  final GuestAccount account;
  final bool isComplete;
}

final class SessionEnded extends AuthState {
  const SessionEnded(this.returnTo);

  final String? returnTo;
}

final class SigningOut extends AuthState {
  const SigningOut();
}

final class RecoveryVerified extends AuthState {
  const RecoveryVerified(this.email);

  final String email;
}

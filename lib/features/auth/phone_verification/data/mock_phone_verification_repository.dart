import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';

/// Temporary stub until US4/US5 replace it with the real Node-backed and
/// ladder-driven implementations (T048). Only `start` answers; the code
/// step is not reachable yet.
final class MockPhoneVerificationRepository
    implements PhoneVerificationRepository {
  @override
  Future<String> start(
    PhoneVerificationDraft draft,
    PhoneVerificationPurpose purpose,
  ) async => 'mock-challenge';

  @override
  Future<WhatsAppChallenge> send(String challengeId) =>
      throw UnimplementedError('US4 replaces this stub');

  @override
  Future<(DeliveryStatus, DeliveryFailure?, SendWindow)> status(
    String challengeId,
  ) => throw UnimplementedError('US4 replaces this stub');

  @override
  Future<GuestAccount> verify(String challengeId, String code) =>
      throw UnimplementedError('US4 replaces this stub');
}

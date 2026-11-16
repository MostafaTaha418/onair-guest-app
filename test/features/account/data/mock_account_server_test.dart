import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/account/data/mock_account_server.dart';
import 'package:on_air/features/account/domain/deletion.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';

void main() {
  late MockAuthRepository auth;
  late MockAccountServer server;

  setUp(() {
    auth = MockAuthRepository();
    server = MockAccountServer(auth: auth, latency: Duration.zero);
  });

  test('the blocked account is refused with one booking blocker', () async {
    await auth.signInEmail(
      'blocked@onair.test',
      MockAuthRepository.legacyPassword,
    );
    await expectLater(
      server.requestDeletion(),
      throwsA(
        isA<DeletionBlockedException>()
            .having(
              (exception) => exception.blockers,
              'blockers',
              hasLength(1),
            )
            .having(
              (exception) => exception.blockers.first.kind,
              'kind',
              DeletionBlockerKind.booking,
            )
            .having(
              (exception) => exception.blockers.first.code,
              'code',
              'OA-BLOCKED',
            ),
      ),
    );
  });

  test('otherwise the request opens a challenge with a masked email', () async {
    await auth.signInEmail(
      'legacy@onair.test',
      MockAuthRepository.legacyPassword,
    );
    final request = await server.requestDeletion();
    expect(request.challengeId, isNotEmpty);
    // a***@g***.com style: first letters only.
    expect(request.maskedEmail, 'l***@o***.test');
    expect(server.challengeCount, 1);
  });

  test('a wrong code is OTP_INVALID; the mock code deletes', () async {
    await auth.signInEmail(
      'legacy@onair.test',
      MockAuthRepository.legacyPassword,
    );
    final request = await server.requestDeletion();
    await expectLater(
      server.confirmDeletion(request.challengeId, '000000'),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.error.code,
          'code',
          ErrorCode.otpInvalid,
        ),
      ),
    );
    expect(server.deleted, isFalse);
    await server.confirmDeletion(
      request.challengeId,
      MockBackend.verificationCode,
    );
    expect(server.deleted, isTrue);
  });

  test(
    'a blocker added between request and confirm refuses at confirm',
    () async {
      await auth.signInEmail(
        'legacy@onair.test',
        MockAuthRepository.legacyPassword,
      );
      final request = await server.requestDeletion();
      server.addLateBlocker(MockAccountServer.blockedBooking);
      await expectLater(
        server.confirmDeletion(
          request.challengeId,
          MockBackend.verificationCode,
        ),
        throwsA(
          isA<DeletionBlockedException>().having(
            (exception) => exception.blockers,
            'blockers',
            hasLength(1),
          ),
        ),
      );
      expect(server.deleted, isFalse);
    },
  );
}

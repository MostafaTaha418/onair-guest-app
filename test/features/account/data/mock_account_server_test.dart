import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/account/data/mock_account_server.dart';
import 'package:on_air/features/account/domain/deletion.dart';
import 'package:on_air/features/account/domain/notification_preference.dart';
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

  group('updateProfile (T072)', () {
    setUp(() async {
      await auth.signInEmail(
        'legacy@onair.test',
        MockAuthRepository.legacyPassword,
      );
    });

    test('a null parameter is omitted from the update', () async {
      await server.updateProfile(locale: 'en');
      final update = server.profileUpdates.single;
      expect(update.fullName, isNull);
      expect(update.locale, 'en');
      expect(server.profileLocale, 'en');
      expect(server.updateProfileCalls, 1);
    });

    test('the name is trimmed and 2-80 characters', () async {
      await server.updateProfile(fullName: '  زائر تجريبي  ');
      expect(auth.account!.fullName, 'زائر تجريبي');
      await expectLater(
        server.updateProfile(fullName: 'ا'),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.validationFailed,
          ),
        ),
      );
      await expectLater(
        server.updateProfile(fullName: List.filled(81, 'x').join()),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.validationFailed,
          ),
        ),
      );
      await expectLater(
        server.updateProfile(fullName: '!!'),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.validationFailed,
          ),
        ),
      );
    });

    test('the locale is ar|en', () async {
      await server.updateProfile(locale: 'ar');
      expect(server.profileLocale, 'ar');
      await expectLater(
        server.updateProfile(locale: 'fr'),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.validationFailed,
          ),
        ),
      );
    });
  });

  group('sessions and password (T081)', () {
    setUp(() async {
      await auth.signInEmail(
        'legacy@onair.test',
        MockAuthRepository.legacyPassword,
      );
    });

    test('lists three sessions with the current one first', () async {
      final sessions = await server.listSessions();
      expect(sessions, hasLength(3));
      expect(sessions.first.isCurrent, isTrue);
    });

    test(
      'cannot end current, can end one, and end-all keeps current',
      () async {
        await expectLater(
          server.endSession('session-current'),
          throwsA(
            isA<AppFailure>().having(
              (failure) => failure.error.code,
              'code',
              ErrorCode.sessionIsCurrent,
            ),
          ),
        );
        await server.endSession('session-ios');
        expect(await server.listSessions(), hasLength(2));
        await server.endOtherSessions();
        final sessions = await server.listSessions();
        expect(sessions, hasLength(1));
        expect(sessions.single.isCurrent, isTrue);
      },
    );

    test('wrong, rate-limited, weak and successful password changes', () async {
      await expectLater(
        server.changePassword(current: 'wrong', next: 'Nextpass1'),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.passwordIncorrect,
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        try {
          await server.changePassword(current: 'wrong', next: 'Nextpass1');
        } on AppFailure {
          // The sixth attempt below is the rate-limited one.
        }
      }
      await expectLater(
        server.changePassword(current: 'wrong', next: 'Nextpass1'),
        throwsA(
          isA<AppFailure>()
              .having(
                (failure) => failure.error.code,
                'code',
                ErrorCode.rateLimited,
              )
              .having(
                (failure) => failure.error.details?['retry_at'],
                'retry_at',
                isNotNull,
              ),
        ),
      );

      // A fresh server has no failed-attempt window.
      server = MockAccountServer(auth: auth, latency: Duration.zero);
      await expectLater(
        server.changePassword(
          current: MockAuthRepository.legacyPassword,
          next: 'weak',
        ),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.passwordWeak,
          ),
        ),
      );
      await server.changePassword(
        current: MockAuthRepository.legacyPassword,
        next: 'Nextpass1',
      );
      expect(await server.listSessions(), hasLength(1));
      expect(auth.currentPasswordMatches('Nextpass1'), isTrue);
    });

    test('social accounts cannot change a password', () async {
      await auth.signOut();
      auth.scenario = MockSocialScenario.completeUser;
      await auth.signInWithGoogle();
      await expectLater(
        server.changePassword(current: 'x', next: 'Nextpass1'),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.actionNotAllowed,
          ),
        ),
      );
    });
  });

  group('notification preferences (T095)', () {
    setUp(() async {
      await auth.signInEmail(
        'legacy@onair.test',
        MockAuthRepository.legacyPassword,
      );
    });

    test('seeds mandatory and optional category channels', () async {
      final preferences = await server.getPreferences();
      final booking = preferences.singleWhere((item) => item.key == 'booking');
      final support = preferences.singleWhere((item) => item.key == 'support');
      expect(booking.isMandatory, isTrue);
      expect(booking.enabled(NotificationChannel.push), isTrue);
      expect(support.isMandatory, isFalse);
      expect(support.enabled(NotificationChannel.email), isTrue);
    });

    test('saves optional channels and rejects mandatory ones', () async {
      await server.setPreference(
        'support',
        NotificationChannel.push,
        false,
      );
      expect(server.pushEnabled('support'), isFalse);
      await expectLater(
        server.setPreference(
          'booking',
          NotificationChannel.push,
          false,
        ),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.validationFailed,
          ),
        ),
      );
      expect(server.pushEnabled('booking'), isTrue);
    });
  });
}

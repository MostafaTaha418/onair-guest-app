import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/auth/domain/egypt_phone.dart';
import 'package:on_air/features/auth/phone_verification/data/mock_otp_server.dart';
import 'package:on_air/features/auth/phone_verification/data/mock_phone_verification_repository.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';

/// T060 — the mock limiter (node-otp.md A8 "Processing order", "Ladder"):
/// the sends 1–9 waits, the 11th request block, the three key scopes and
/// the resets. The clock is injected and driven inside `fakeAsync`, so no
/// real second ever passes.
void main() {
  const account = 'acct-1';
  const phone = '+201012345678';
  const device = 'device-1';
  const secondDevice = 'device-2';

  /// A server over a mutable instant: `advance` moves the clock.
  (MockOtpServer, void Function(Duration)) server() {
    var now = DateTime.utc(2026, 11, 14, 10);
    final mock = MockOtpServer(clock: () => now);
    return (mock, (Duration delta) => now = now.add(delta));
  }

  /// Sends [times] codes, waiting the reported window out before each next
  /// send; returns the window of the last send.
  SendWindow burn(
    MockOtpServer mock,
    void Function(Duration) advance,
    int times,
  ) {
    var window = SendWindow(serverTime: DateTime.utc(1970));
    for (var sent = 0; sent < times; sent++) {
      final wait = window.remainingUntilSend(mock.clock());
      if (wait > Duration.zero) advance(wait);
      window = mock.send(accountId: account, phone: phone, deviceId: device);
    }
    return window;
  }

  AppFailure failureOf(Object Function() action) {
    try {
      action();
    } on AppFailure catch (failure) {
      return failure;
    }
    fail('the send was expected to fail');
  }

  test('the waits after sends 1–9 follow the ladder exactly', () {
    fakeAsync((_) {
      final (mock, advance) = server();
      const waits = [
        Duration(seconds: 30),
        Duration(minutes: 5),
        Duration(hours: 1),
        Duration(hours: 24),
        Duration(hours: 1),
        Duration(hours: 24),
        Duration(hours: 1),
        Duration(hours: 24),
        Duration(hours: 1),
      ];
      var window = SendWindow(serverTime: DateTime.utc(1970));
      for (var sent = 1; sent <= 9; sent++) {
        final wait = window.remainingUntilSend(mock.clock());
        if (wait > Duration.zero) advance(wait);
        final before = mock.clock();
        window = mock.send(accountId: account, phone: phone, deviceId: device);
        expect(
          window.nextSendAt!.difference(window.serverTime),
          waits[sent - 1],
          reason: 'wait after send $sent',
        );
        expect(window.serverTime, before);
        expect(window.blockedUntil, isNull);
      }
    });
  });

  test('a request before nextSendAt is RATE_LIMITED with the window', () {
    fakeAsync((_) {
      final (mock, advance) = server();
      burn(mock, advance, 1);
      final before = mock.clock();
      final failure = failureOf(
        () => mock.send(accountId: account, phone: phone, deviceId: device),
      );
      expect(failure.error.code, ErrorCode.rateLimited);
      expect(
        DateTime.parse(failure.error.details!['next_send_at'] as String),
        mock.counters('acct:$account').nextSendAt,
      );
      expect(
        DateTime.parse(failure.error.details!['server_time'] as String),
        before,
      );
      // The rejected attempt never counted.
      expect(mock.counters('acct:$account').sendCount, 1);
    });
  });

  test('the 11th request blocks the account, phone and device keys', () {
    fakeAsync((_) {
      final (mock, advance) = server();
      burn(mock, advance, 10);
      final before = mock.clock();
      final failure = failureOf(
        () => mock.send(accountId: account, phone: phone, deviceId: device),
      );
      expect(failure.error.code, ErrorCode.otpSendBlocked);
      final blockedUntil = DateTime.parse(
        failure.error.details!['blocked_until'] as String,
      );
      expect(blockedUntil, before.add(const Duration(days: 7)));
      expect(
        DateTime.parse(failure.error.details!['server_time'] as String),
        before,
      );
      for (final key in ['acct:$account', 'phone:$phone', 'dev:$device']) {
        expect(mock.counters(key).blockedUntil, blockedUntil, reason: key);
        expect(mock.counters(key).sendCount, 10, reason: key);
      }
    });
  });

  test('a new account on the same device is blocked too', () {
    fakeAsync((_) {
      final (mock, advance) = server();
      burn(mock, advance, 10);
      failureOf(
        () => mock.send(accountId: account, phone: phone, deviceId: device),
      ); // the 11th: blocks the three keys
      final failure = failureOf(
        () => mock.send(
          accountId: 'acct-2',
          phone: '+201098765432',
          deviceId: device,
        ),
      );
      expect(failure.error.code, ErrorCode.otpSendBlocked);
      expect(
        mock.counters('dev:$device').blockedUntil,
        isNotNull,
        reason: 'the device key carries the block',
      );
    });
  });

  test('the same phone from another device and account is blocked too', () {
    fakeAsync((_) {
      final (mock, advance) = server();
      burn(mock, advance, 10);
      failureOf(
        () => mock.send(accountId: account, phone: phone, deviceId: device),
      );
      final failure = failureOf(
        () => mock.send(
          accountId: 'acct-3',
          phone: phone,
          deviceId: secondDevice,
        ),
      );
      expect(failure.error.code, ErrorCode.otpSendBlocked);
      expect(
        mock.counters('phone:$phone').blockedUntil,
        isNotNull,
        reason: 'the phone key carries the block',
      );
    });
  });

  test('after 7 days the block ends and the counters reset', () {
    fakeAsync((_) {
      final (mock, advance) = server();
      burn(mock, advance, 10);
      failureOf(
        () => mock.send(accountId: account, phone: phone, deviceId: device),
      );
      advance(const Duration(days: 7, seconds: 1));
      // The strictest idle lastSendAt is 7+ days old: the counters reset and
      // the ladder restarts from 30 s.
      final window = mock.send(
        accountId: account,
        phone: phone,
        deviceId: device,
      );
      expect(
        window.nextSendAt!.difference(window.serverTime),
        const Duration(seconds: 30),
      );
      expect(mock.counters('acct:$account').sendCount, 1);
      expect(
        mock.counters('acct:$account').blockedUntil,
        isNotNull,
        reason: 'blocks are not reset, they expire',
      );
    });
  });

  test('7 idle days without a block reset the counters', () {
    fakeAsync((_) {
      final (mock, advance) = server();
      burn(mock, advance, 3);
      expect(mock.counters('acct:$account').sendCount, 3);
      advance(const Duration(days: 7, seconds: 1));
      final window = mock.send(
        accountId: account,
        phone: phone,
        deviceId: device,
      );
      expect(
        window.nextSendAt!.difference(window.serverTime),
        const Duration(seconds: 30),
      );
      expect(mock.counters('acct:$account').sendCount, 1);
    });
  });

  test('success via verify resets the three keys, the block stands', () {
    fakeAsync((_) {
      final (mock, advance) = server();
      burn(mock, advance, 4);
      mock.countSuccess(
        accountId: account,
        phone: phone,
        deviceId: device,
      );
      for (final key in ['acct:$account', 'phone:$phone', 'dev:$device']) {
        expect(mock.counters(key).sendCount, 0, reason: key);
        expect(mock.counters(key).nextSendAt, isNull, reason: key);
        expect(mock.counters(key).blockedUntil, isNull, reason: key);
      }
      // The ladder restarts.
      final window = mock.send(
        accountId: account,
        phone: phone,
        deviceId: device,
      );
      expect(
        window.nextSendAt!.difference(window.serverTime),
        const Duration(seconds: 30),
      );
    });
  });

  test('attestationFails throws APP_ATTESTATION_FAILED and counts nothing', () {
    fakeAsync((_) {
      final (mock, _) = server();
      mock.attestationFails = true;
      final failure = failureOf(
        () => mock.send(accountId: account, phone: phone, deviceId: device),
      );
      expect(failure.error.code, ErrorCode.appAttestationFailed);
      expect(mock.callLog, ['send.attestationFailed']);
      for (final key in ['acct:$account', 'phone:$phone', 'dev:$device']) {
        expect(mock.counters(key).sendCount, 0, reason: key);
        expect(mock.counters(key).lastSendAt, isNull, reason: key);
      }
    });
  });

  test('a send that will not reach WhatsApp still counts', () async {
    final (mock, _) = server();
    final auth = MockAuthRepository(clock: mock.clock)
      ..scenario = MockSocialScenario.newUser;
    await auth.signInWithGoogle();
    final repo = MockPhoneVerificationRepository(
      auth: auth,
      deviceIdentity: const MemoryDeviceIdentity(device),
      otpServer: mock,
    )..clock = mock.clock;
    // The delivery poll answers failed/not_on_whatsapp for numbers ending
    // 0000; the limiter cannot know that in advance (A8 step 7).
    final challengeId = await repo.start(
      PhoneVerificationDraft(
        phone: EgyptPhone.tryParse('01000000000')!,
        locale: 'ar',
      ),
      PhoneVerificationPurpose.register,
    );
    final window = (await repo.send(challengeId)).window;
    expect(
      window.nextSendAt!.difference(window.serverTime),
      const Duration(seconds: 30),
      reason: 'the first send sits at the top of the ladder',
    );
    expect(mock.callLog, contains('send'));
    expect(mock.counters('acct:${auth.account!.id}').sendCount, 1);
  });
}

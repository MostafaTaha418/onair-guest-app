import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/session/session_heartbeat.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('runs on resume and each minute, and pauses with the app', () {
    fakeAsync((async) {
      var calls = 0;
      final heartbeat = SessionHeartbeat(
        heartbeat: () async => calls++,
        isSignedIn: () => true,
        onSessionEnded: () {},
      )..start();
      async.flushMicrotasks();
      expect(calls, 1);
      async
        ..elapse(const Duration(seconds: 60))
        ..flushMicrotasks();
      expect(calls, 2);
      heartbeat.didChangeAppLifecycleState(AppLifecycleState.paused);
      async
        ..elapse(const Duration(minutes: 2))
        ..flushMicrotasks();
      expect(calls, 2);
      heartbeat.didChangeAppLifecycleState(AppLifecycleState.resumed);
      async.flushMicrotasks();
      expect(calls, 3);
      heartbeat.dispose();
    });
  });

  test('revoked and unauthenticated end the session exactly once', () {
    for (final code in [ErrorCode.sessionRevoked, ErrorCode.unauthenticated]) {
      fakeAsync((async) {
        var ended = 0;
        final heartbeat = SessionHeartbeat(
          heartbeat: () async => throw AppFailure(
            ApiError(code: code, messageKey: 'errorUnauthenticated'),
          ),
          isSignedIn: () => true,
          onSessionEnded: () => ended++,
        )..start();
        async
          ..flushMicrotasks()
          ..elapse(const Duration(minutes: 2))
          ..flushMicrotasks();
        expect(ended, 1);
        heartbeat.dispose();
      });
    }
  });

  test('visitors and ordinary errors do not end or repeat work', () {
    fakeAsync((async) {
      var calls = 0;
      var ended = 0;
      var signedIn = false;
      final heartbeat = SessionHeartbeat(
        heartbeat: () async {
          calls++;
          throw const AppFailure(
            ApiError(code: ErrorCode.network, messageKey: 'errorNoConnection'),
          );
        },
        isSignedIn: () => signedIn,
        onSessionEnded: () => ended++,
      )..start();
      async.flushMicrotasks();
      expect(calls, 0);
      signedIn = true;
      heartbeat.didChangeAppLifecycleState(AppLifecycleState.resumed);
      async.flushMicrotasks();
      expect(calls, 1);
      expect(ended, 0);
      heartbeat.dispose();
    });
  });
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:on_air/core/auth/secure_session_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class _SecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _SecureStorage secureStorage;
  late SecureSessionStorage sessionStorage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    secureStorage = _SecureStorage();
    sessionStorage = SecureSessionStorage(storage: secureStorage);
  });

  test('persists and reads the session only through secure storage', () async {
    when(
      () => secureStorage.write(
        key: SecureSessionStorage.sessionKey,
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => secureStorage.read(key: SecureSessionStorage.sessionKey),
    ).thenAnswer((_) async => '{"access_token":"secret"}');

    await sessionStorage.persistSession('{"access_token":"secret"}');

    expect(await sessionStorage.hasAccessToken(), isTrue);
    expect(
      await sessionStorage.accessToken(),
      '{"access_token":"secret"}',
    );
    verify(
      () => secureStorage.write(
        key: SecureSessionStorage.sessionKey,
        value: '{"access_token":"secret"}',
      ),
    ).called(1);
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
  });

  test('removes the persisted secure session', () async {
    when(
      () => secureStorage.delete(key: SecureSessionStorage.sessionKey),
    ).thenAnswer((_) async {});

    await sessionStorage.removePersistedSession();

    verify(
      () => secureStorage.delete(key: SecureSessionStorage.sessionKey),
    ).called(1);
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
  });
}

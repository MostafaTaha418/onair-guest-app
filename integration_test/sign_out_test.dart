import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/auth/secure_session_storage.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/main_staging.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart';

const _phone = String.fromEnvironment('STAGING_TEST_PHONE');
const _otp = String.fromEnvironment('STAGING_TEST_OTP');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'sign-out clears the secure session and returns to visitor Home',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle();

      final routeContext = tester.element(find.byType(Scaffold).first);
      final router = GoRouter.of(routeContext);
      final auth = routeContext.read<AuthCubit>();
      if (auth.state is! SignedIn) {
        router.go(AppRoutes.login);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('phone-field')),
          _phone,
        );
        await tester.tap(find.byKey(const ValueKey('send-code-button')));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.enterText(find.byType(TextField), _otp);
        await tester.pumpAndSettle();
      }

      expect(auth.state, isA<SignedIn>());
      final signedIn = auth.state as SignedIn;
      if (!signedIn.isComplete) {
        await tester.enterText(
          find.byKey(const ValueKey('full-name-field')),
          'Staging Sign-out Guest',
        );
        await tester.tap(find.byKey(const ValueKey('terms-checkbox')));
        await tester.tap(
          find.byKey(const ValueKey('complete-profile-button')),
        );
        await tester.pumpAndSettle();
      }
      router.go(AppRoutes.account);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('sign-out-button')));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, AppRoutes.home);
      expect(auth.state, isA<SignedOut>());
      expect(Supabase.instance.client.auth.currentSession, isNull);
      expect(await SecureSessionStorage().hasAccessToken(), isFalse);
    },
    skip: _phone.isEmpty || _otp.isEmpty,
  );
}

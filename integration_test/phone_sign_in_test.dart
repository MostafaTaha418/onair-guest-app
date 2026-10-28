import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/main_staging.dart' as app;

const _phone = String.fromEnvironment('STAGING_TEST_PHONE');
const _otp = String.fromEnvironment('STAGING_TEST_OTP');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'phone sign-up, profile completion, sign-out, and repeat sign-in',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle();

      final routeContext = tester.element(find.byType(Scaffold).first);
      final router = GoRouter.of(routeContext);
      final auth = routeContext.read<AuthCubit>();
      router.go(AppRoutes.login);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('phone-field')),
        _phone,
      );
      await tester.tap(find.byKey(const ValueKey('send-code-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField), _otp);
      await tester.pumpAndSettle();

      expect(auth.state, isA<SignedIn>());
      final signedIn = auth.state as SignedIn;
      if (!signedIn.isComplete) {
        await tester.enterText(
          find.byKey(const ValueKey('full-name-field')),
          'Staging Guest',
        );
        await tester.tap(find.byKey(const ValueKey('terms-checkbox')));
        await tester.tap(
          find.byKey(const ValueKey('complete-profile-button')),
        );
        await tester.pumpAndSettle();
      }
      expect((auth.state as SignedIn).account.phoneVerified, isTrue);

      await auth.signOut();
      router.go(AppRoutes.login);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('phone-field')),
        _phone,
      );
      await tester.tap(find.byKey(const ValueKey('send-code-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField), _otp);
      await tester.pumpAndSettle();
      expect(auth.state, isA<SignedIn>());
    },
    skip: _phone.isEmpty || _otp.isEmpty,
  );
}

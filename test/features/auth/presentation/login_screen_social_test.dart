import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/social_sign_in_button.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/domain/social_identity.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/auth/presentation/login_screen.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeAppConfigRepository config;

  setUp(() {
    auth = FakeAuthRepository()
      ..account = GuestAccount(
        id: 'guest',
        status: AccountStatus.active,
        phone: '+201012345678',
        phoneVerified: true,
        email: 'guest@example.com',
        emailVerified: true,
        fullName: 'Guest',
        acceptedTermsVersion: 'v1',
      );
    config = FakeAppConfigRepository(
      const AppConfig(
        minSupportedBuildAndroid: 1,
        minSupportedBuildIos: 1,
        supportPhone: '+201000000000',
        currentTermsVersion: 'v1',
      ),
    );
  });

  Future<void> pumpLogin(
    WidgetTester tester,
    TargetPlatform platform,
  ) async {
    // A tall surface keeps the social row built (a lazy ListView never
    // materializes it below the fold).
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpOnAirApp(
      _PlatformScope(
        platform: platform,
        child: const LoginScreen(),
      ),
      authRepository: auth,
      appConfigRepository: config,
    );
  }

  Finder appleButton() => find.byKey(const ValueKey('social-apple-button'));
  Finder googleButton() => find.byKey(const ValueKey('social-google-button'));

  testWidgets('iOS shows Apple then Google', (tester) async {
    await pumpLogin(tester, TargetPlatform.iOS);

    expect(appleButton(), findsOneWidget);
    expect(googleButton(), findsOneWidget);
    // RTL: Apple comes before Google in the reading order.
    expect(
      tester.getTopLeft(appleButton()).dx,
      greaterThan(tester.getTopLeft(googleButton()).dx),
    );
  });

  testWidgets('Android shows Google only', (tester) async {
    await pumpLogin(tester, TargetPlatform.android);

    expect(appleButton(), findsNothing);
    expect(googleButton(), findsOneWidget);
  });

  testWidgets('while Apple is busy Google is disabled', (tester) async {
    await pumpLogin(tester, TargetPlatform.iOS);
    final cubit = tester.element(find.byType(LoginScreen)).read<AuthCubit>();

    cubit.social.value = const SocialSignInUiState(busy: SocialProvider.apple);
    await tester.pump();

    expect(
      tester.widget<InkWell>(appleButton()).onTap,
      isNull,
      reason: 'Apple shows the loader and ignores taps',
    );
    expect(
      tester.widget<InkWell>(googleButton()).onTap,
      isNull,
      reason: 'every social button is disabled during a sign-in',
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('the email submit is disabled while any sheet is in flight', (
    tester,
  ) async {
    await pumpLogin(tester, TargetPlatform.android);
    final cubit = tester.element(find.byType(LoginScreen)).read<AuthCubit>();

    cubit.social.value = const SocialSignInUiState(
      busy: SocialProvider.google,
    );
    await tester.pump();

    expect(
      tester
          .widget<OnAirPrimaryButton>(
            find.byKey(const ValueKey('email-submit-button')),
          )
          .onPressed,
      isNull,
    );
  });
}

/// Sets the target platform for the pumped tree and resets it in dispose,
/// so the binding's end-of-test foundation invariant still holds.
class _PlatformScope extends StatefulWidget {
  const _PlatformScope({required this.platform, required this.child});

  final TargetPlatform platform;
  final Widget child;

  @override
  State<_PlatformScope> createState() => _PlatformScopeState();
}

class _PlatformScopeState extends State<_PlatformScope> {
  @override
  void initState() {
    super.initState();
    debugDefaultTargetPlatformOverride = widget.platform;
  }

  @override
  void dispose() {
    debugDefaultTargetPlatformOverride = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

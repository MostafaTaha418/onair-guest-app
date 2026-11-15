import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/features/account/presentation/account_placeholder_screen.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/features/auth/phone_verification/presentation/confirm_phone_screen.dart';
import 'package:on_air/features/auth/phone_verification/presentation/phone_verification_cubit.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';

import '../../helpers/fake_app_config_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/pump_until_found.dart';

/// Review fix 7: the «أكّد رقمك» success publishes the fresh profile the
/// flow returned (`PvDone.account`) through `AuthCubit.applyAccount`, so the
/// account rows show the new masked phone without waiting for a refresh.
final class _ChangeRepository implements PhoneVerificationRepository {
  @override
  Future<String> start(
    PhoneVerificationDraft draft,
    PhoneVerificationPurpose purpose,
  ) async {
    expect(purpose, PhoneVerificationPurpose.change);
    return 'challenge-change';
  }

  @override
  Future<WhatsAppChallenge> send(String challengeId) async {
    final now = DateTime.now().toUtc();
    return WhatsAppChallenge(
      challengeId: challengeId,
      maskedPhone: '+20 10•• ••• 432',
      expiresAt: now.add(const Duration(minutes: 10)),
      window: SendWindow(serverTime: now, receivedAt: now),
    );
  }

  @override
  Future<(DeliveryStatus, DeliveryFailure?, SendWindow)> status(
    String challengeId,
  ) async {
    final now = DateTime.now().toUtc();
    return (
      DeliveryStatus.delivered,
      null,
      SendWindow(serverTime: now, receivedAt: now),
    );
  }

  @override
  Future<GuestAccount> verify(String challengeId, String code) async {
    expect(code, '123456');
    // The server's answer: the same account with the NEW confirmed number.
    return GuestAccount(
      id: 'account-guest',
      status: AccountStatus.active,
      phone: '+201098765432',
      phoneVerified: true,
      email: 'legacy@onair.test',
      emailVerified: true,
      fullName: 'Legacy Guest',
      authProviders: const {AuthProvider.google},
      acceptedTermsVersion: 'v1',
    );
  }
}

void main() {
  testWidgets('a change-number success shows the new masked phone on the '
      'account rows', (tester) async {
    final auth = FakeAuthRepository()
      ..account = GuestAccount(
        id: 'account-guest',
        status: AccountStatus.active,
        phone: '+201012340000',
        phoneVerified: true,
        email: 'legacy@onair.test',
        emailVerified: true,
        fullName: 'Legacy Guest',
        authProviders: const {AuthProvider.google},
        acceptedTermsVersion: 'v1',
      );
    final cubit = AuthCubit(auth);
    await cubit.restore();
    final config = FakeAppConfigRepository(
      const AppConfig(
        minSupportedBuildAndroid: 1,
        minSupportedBuildIos: 1,
        supportPhone: '+201000000000',
        currentTermsVersion: 'v1',
      ),
    );

    late final GoRouter router;
    router = GoRouter(
      initialLocation: AppRoutes.account,
      routes: [
        GoRoute(
          path: AppRoutes.account,
          builder: (_, _) => const AccountPlaceholderScreen(),
        ),
        GoRoute(
          path: AppRoutes.accountPhone,
          builder: (context, _) => BlocProvider<PhoneVerificationCubit>(
            create: (context) => PhoneVerificationCubit(
              _ChangeRepository(),
              purpose: PhoneVerificationPurpose.change,
              needsName: false,
              needsTerms: false,
              locale: 'ar',
              currentTermsVersion: 'v1',
            ),
            child: const ConfirmPhoneScreen(
              purpose: PhoneVerificationPurpose.change,
            ),
          ),
        ),
      ],
    );
    await tester.pumpOnAirApp(
      const SizedBox.shrink(),
      authRepository: auth,
      appConfigRepository: config,
      authCubit: cubit,
      routerConfig: router,
    );
    await tester.pump();

    unawaited(router.push(AppRoutes.accountPhone));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('confirm-phone-field')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('confirm-phone-field')),
      '01098765432',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirm-phone-continue')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('whatsapp-otp-field')),
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('whatsapp-otp-field')),
        matching: find.byType(TextField),
      ),
      '123456',
    );
    await tester.tap(find.byKey(const ValueKey('whatsapp-confirm')));
    // The success pops the screen and shows a snackbar (a real timer) —
    // fixed pumps instead of pumpAndSettle (periodic-timer deadlock).
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      if (find
          .byKey(const ValueKey('account-phone-row'), skipOffstage: false)
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    // The pop returned with `true` and the account rows already show the
    // new masked number.
    expect(
      find.text('+20 10•• ••• 432', skipOffstage: false),
      findsOneWidget,
    );
    expect(cubit.state, isA<SignedIn>());
    expect(
      (cubit.state as SignedIn).account.phone,
      '+201098765432',
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/features/auth/phone_verification/presentation/confirm_phone_screen.dart';
import 'package:on_air/features/auth/phone_verification/presentation/phone_verification_cubit.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/pump_app.dart';

final class _FakeRepository implements PhoneVerificationRepository {
  Exception? startError;
  int startCalls = 0;
  PhoneVerificationDraft? lastDraft;

  @override
  Future<String> start(
    PhoneVerificationDraft draft,
    PhoneVerificationPurpose purpose,
  ) async {
    startCalls += 1;
    lastDraft = draft;
    if (startError case final error?) throw error;
    return 'challenge-1';
  }

  @override
  Future<WhatsAppChallenge> send(String challengeId) =>
      throw UnimplementedError();

  @override
  Future<(DeliveryStatus, DeliveryFailure?, SendWindow)> status(
    String challengeId,
  ) => throw UnimplementedError();

  @override
  Future<GuestAccount> verify(String challengeId, String code) =>
      throw UnimplementedError();
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('ar'));
  late _FakeRepository repo;
  late FakeAuthRepository auth;
  late FakeAppConfigRepository config;
  late FakeBookingBackend backend;

  setUp(() {
    repo = _FakeRepository();
    backend = FakeBookingBackend();
    config = FakeAppConfigRepository(
      const AppConfig(
        minSupportedBuildAndroid: 1,
        minSupportedBuildIos: 1,
        supportPhone: '+201000000000',
        currentTermsVersion: 'v1',
      ),
    );
  });

  GuestAccount incompleteAccount() => GuestAccount(
    id: 'guest',
    status: AccountStatus.incomplete,
    email: 'guest@example.com',
    emailVerified: true,
  );

  GuestAccount legacyAccount() => GuestAccount(
    id: 'guest',
    status: AccountStatus.active,
    phone: '+201012345678',
    phoneVerified: true,
    email: 'legacy@example.com',
    emailVerified: true,
    fullName: 'Legacy Guest',
    acceptedTermsVersion: 'v1',
  );

  Future<AuthCubit> pumpScreen(
    WidgetTester tester, {
    required GuestAccount account,
    required bool needsName,
    required bool needsTerms,
    String? prefilledName,
  }) async {
    auth = FakeAuthRepository()..account = account;
    final cubit = AuthCubit(auth);
    addTearDown(cubit.close);
    await cubit.restore();
    expect(cubit.state, isA<SignedIn>());

    final phoneCubit = PhoneVerificationCubit(
      repo,
      purpose: PhoneVerificationPurpose.register,
      needsName: needsName,
      needsTerms: needsTerms,
      prefilledName: prefilledName,
      locale: 'ar',
      currentTermsVersion: 'v1',
    );
    addTearDown(phoneCubit.close);

    // A tall surface keeps every form control built (a lazy ListView never
    // materializes content below the fold).
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpOnAirApp(
      BlocProvider<PhoneVerificationCubit>.value(
        value: phoneCubit,
        child: const ConfirmPhoneScreen(
          purpose: PhoneVerificationPurpose.register,
        ),
      ),
      authRepository: auth,
      authCubit: cubit,
      appConfigRepository: config,
      bookingBackend: backend,
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets(
    'register with a missing name shows name, phone, terms and the email',
    (tester) async {
      await pumpScreen(
        tester,
        account: incompleteAccount(),
        needsName: true,
        needsTerms: true,
      );

      expect(
        find.byKey(const ValueKey('confirm-phone-name-field')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('confirm-phone-field')), findsOneWidget);
      expect(find.byKey(const ValueKey('confirm-phone-terms')), findsOneWidget);
      expect(find.byKey(const ValueKey('confirm-phone-email')), findsOneWidget);
      expect(find.text(l10n.confirmPhoneEmailLabel), findsOneWidget);
      expect(find.text('guest@example.com'), findsOneWidget);
    },
  );

  testWidgets('a legacy-like account sees the phone field only', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      account: legacyAccount(),
      needsName: false,
      needsTerms: false,
    );

    expect(find.byKey(const ValueKey('confirm-phone-field')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('confirm-phone-name-field')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('confirm-phone-terms')), findsNothing);
    expect(find.byKey(const ValueKey('confirm-phone-email')), findsNothing);
  });

  testWidgets('«متابعة» is disabled until the form is valid', (tester) async {
    await pumpScreen(
      tester,
      account: incompleteAccount(),
      needsName: true,
      needsTerms: true,
    );

    OnAirPrimaryButton buttonWidget() => tester.widget<OnAirPrimaryButton>(
      find.byKey(const ValueKey('confirm-phone-continue')),
    );
    expect(buttonWidget().onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('confirm-phone-field')),
      '01012345678',
    );
    await tester.pump();
    expect(buttonWidget().onPressed, isNull, reason: 'no name yet');

    await tester.enterText(
      find.byKey(const ValueKey('confirm-phone-name-field')),
      'Mona Adel',
    );
    await tester.pump();
    expect(buttonWidget().onPressed, isNull, reason: 'terms not accepted');

    await tester.tap(find.byKey(const ValueKey('confirm-phone-terms')));
    await tester.pump();
    expect(buttonWidget().onPressed, isNotNull);
  });

  testWidgets('the back button asks before leaving and «كمّل» keeps entries', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      account: incompleteAccount(),
      needsName: true,
      needsTerms: true,
    );

    await tester.enterText(
      find.byKey(const ValueKey('confirm-phone-field')),
      '01012345678',
    );
    await tester.pump();

    final backButton = find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(IconButton),
    );
    await tester.tap(backButton);
    await tester.pumpAndSettle();
    expect(find.text(l10n.confirmPhoneLeaveTitle), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('confirm-phone-leave-stay')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.confirmPhoneLeaveTitle), findsNothing);
    expect(find.text('01012345678'), findsOneWidget);
    expect(find.byKey(const ValueKey('confirm-phone-title')), findsOneWidget);
  });

  testWidgets('«خروج» signs the guest out and returns to a public route', (
    tester,
  ) async {
    auth = FakeAuthRepository()..account = incompleteAccount();
    final authCubit = AuthCubit(auth);
    addTearDown(authCubit.close);
    await authCubit.restore();

    final phoneCubit = PhoneVerificationCubit(
      repo,
      purpose: PhoneVerificationPurpose.register,
      needsName: true,
      needsTerms: true,
      locale: 'ar',
      currentTermsVersion: 'v1',
    );
    addTearDown(phoneCubit.close);

    final router = GoRouter(
      initialLocation: '${AppRoutesScreens.completeProfile}?from=%2Fbookings',
      routes: [
        GoRoute(
          path: AppRoutesScreens.completeProfile,
          builder: (context, state) =>
              BlocProvider<PhoneVerificationCubit>.value(
                value: phoneCubit,
                child: ConfirmPhoneScreen(
                  purpose: PhoneVerificationPurpose.register,
                  from: state.uri.queryParameters['from'],
                ),
              ),
        ),
        GoRoute(
          path: AppRoutesScreens.home,
          builder: (_, _) =>
              const Text('home-probe', key: ValueKey('home-probe')),
        ),
      ],
    );

    await tester.pumpOnAirApp(
      const SizedBox.shrink(),
      authRepository: auth,
      authCubit: authCubit,
      appConfigRepository: config,
      routerConfig: router,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('confirm-phone-title')), findsOneWidget);

    final backButton = find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(IconButton),
    );
    await tester.tap(backButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-phone-leave-confirm')));
    await tester.pumpAndSettle();

    expect(authCubit.state, isA<SignedOut>());
    expect(find.byKey(const ValueKey('home-probe')), findsOneWidget);
  });

  testWidgets('the phone number is stored nowhere after dispose', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      account: incompleteAccount(),
      needsName: true,
      needsTerms: true,
    );

    await tester.enterText(
      find.byKey(const ValueKey('confirm-phone-field')),
      '01012345678',
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(repo.startCalls, 0);
    expect(repo.lastDraft, isNull);
    expect(await backend.secureStore.readAll(), isEmpty);
  });
}

/// Local aliases so the test reads like the production router.
abstract final class AppRoutesScreens {
  static const completeProfile = '/auth/complete-profile';
  static const home = '/home';
}

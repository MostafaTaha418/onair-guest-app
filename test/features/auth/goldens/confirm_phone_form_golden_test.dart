@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/features/auth/phone_verification/presentation/confirm_phone_screen.dart';
import 'package:on_air/features/auth/phone_verification/presentation/phone_verification_cubit.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';

final class _StubRepository implements PhoneVerificationRepository {
  @override
  Future<String> start(
    PhoneVerificationDraft draft,
    PhoneVerificationPurpose purpose,
  ) async => 'challenge-1';

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

/// Asset images decode on the real event loop: step outside the fake async
/// zone briefly, then pump again so everything is painted in the golden.
Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync<void>(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}

Widget _screen({
  required ThemeMode mode,
  required TextDirection direction,
  required double scale,
  required double width,
  required double height,
  required bool fullForm,
  bool keyboardOpen = false,
}) {
  final account = fullForm
      ? GuestAccount(
          id: 'guest',
          status: AccountStatus.incomplete,
          email: 'mona@privaterelay.appleid.com',
          emailVerified: true,
        )
      : GuestAccount(
          id: 'guest',
          status: AccountStatus.incomplete,
          phone: '+201012345678',
          email: 'guest@example.com',
          emailVerified: true,
          fullName: 'Mona Adel',
          acceptedTermsVersion: 'v1',
        );
  final auth = FakeAuthRepository()..account = account;
  final authCubit = AuthCubit(auth);
  unawaited(authCubit.restore());
  final phoneCubit = PhoneVerificationCubit(
    _StubRepository(),
    purpose: PhoneVerificationPurpose.register,
    needsName: fullForm,
    needsTerms: fullForm,
    locale: 'ar',
    currentTermsVersion: 'v1',
  );
  return RepositoryProvider<AppConfigSource>(
    create: (_) => FakeAppConfigRepository(
      const AppConfig(
        minSupportedBuildAndroid: 1,
        minSupportedBuildIos: 1,
        supportPhone: '+201000000000',
        currentTermsVersion: 'v1',
      ),
    ),
    child: BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: BlocProvider<PhoneVerificationCubit>.value(
        value: phoneCubit,
        child: SizedBox(
          width: width,
          height: height,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: OnAirTheme.light,
            darkTheme: OnAirTheme.dark,
            themeMode: mode,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
                viewInsets: keyboardOpen
                    ? const EdgeInsets.only(bottom: 300)
                    : MediaQuery.of(context).viewInsets,
              ),
              child: Directionality(textDirection: direction, child: child!),
            ),
            home: const ConfirmPhoneScreen(
              purpose: PhoneVerificationPurpose.register,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final (formName, fullForm) in [('full', true), ('number_only', false)]) {
    for (final (modeName, mode) in [
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ]) {
      for (final (dirName, direction) in [
        ('rtl', TextDirection.rtl),
        ('ltr', TextDirection.ltr),
      ]) {
        for (final (scaleName, scale) in [('1_0', 1.0), ('1_3', 1.3)]) {
          for (final (widthName, width) in [('320', 320.0), ('800', 800.0)]) {
            unawaited(
              goldenTest(
                'confirm_phone_$formName — $modeName $dirName $scaleName $widthName',
                fileName:
                    'confirm_phone_${formName}_${modeName}_${dirName}_${scaleName}_$widthName',
                constraints: BoxConstraints(
                  maxWidth: width + 20,
                  maxHeight: 850,
                ),
                pumpBeforeTest: _pump,
                builder: () => GoldenTestScenario(
                  name: '$modeName/$dirName/$scaleName/$widthName',
                  child: _screen(
                    mode: mode,
                    direction: direction,
                    scale: scale,
                    width: width,
                    height: 800,
                    fullForm: fullForm,
                  ),
                ),
              ),
            );
          }
        }
      }
    }
  }
  unawaited(
    goldenTest(
      'confirm_phone_full — keyboard open',
      fileName: 'confirm_phone_full_keyboard',
      constraints: const BoxConstraints(maxWidth: 380, maxHeight: 850),
      pumpBeforeTest: _pump,
      builder: () => GoldenTestScenario(
        name: 'keyboard',
        child: _screen(
          mode: ThemeMode.light,
          direction: TextDirection.rtl,
          scale: 1,
          width: 360,
          height: 800,
          fullForm: true,
          keyboardOpen: true,
        ),
      ),
    ),
  );
}

@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/settings/app_settings_cubit.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/payments/in_app_browser.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/account/presentation/account_screen.dart';
import 'package:on_air/features/account_gate/application/sign_out_service.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/support/domain/support_repository.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_support_repository.dart';

class _AccountAuthRepository extends Fake implements AuthRepository {
  @override
  Stream<GuestAccount?> get authStateChanges => const Stream.empty();
}

class _NoopSignOut extends Fake implements SignOutCoordinator {
  @override
  Future<void> signOut() async {}
}

class _NoopBrowser extends Fake implements InAppBrowser {
  @override
  Future<void> open(Uri url, {required String bookingId}) async {}
}

void main() {
  final states = <(String, GuestAccount?)>[
    (
      'email',
      GuestAccount(
        id: 'email-user',
        status: AccountStatus.active,
        phone: '+201012345678',
        phoneVerified: true,
        email: 'mona@onair.test',
        emailVerified: true,
        fullName: 'منى إبراهيم',
        authProviders: const {AuthProvider.email},
      ),
    ),
    (
      'google',
      GuestAccount(
        id: 'google-user',
        status: AccountStatus.active,
        phone: '+201012345678',
        phoneVerified: true,
        email: 'mona@gmail.com',
        emailVerified: true,
        fullName: 'Mona Ibrahim',
        authProviders: const {AuthProvider.google},
        hasPassword: false,
      ),
    ),
    ('visitor', null),
  ];

  for (final (stateName, account) in states) {
    for (final (themeName, themeMode) in [
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ]) {
      for (final (localeName, locale) in [
        ('ar_rtl', const Locale('ar')),
        ('en_ltr', const Locale('en')),
      ]) {
        for (final (scaleName, textScale) in [
          ('1_0', 1.0),
          ('1_3', 1.3),
        ]) {
          for (final width in [320.0, 800.0]) {
            final widthName = width.toInt();
            final variant =
                '${themeName}_${localeName}_${scaleName}_$widthName';
            unawaited(
              goldenTest(
                'account — $stateName $variant',
                fileName: 'account_screen_${stateName}_$variant',
                constraints: BoxConstraints(
                  maxWidth: width + 40,
                  maxHeight: 920,
                ),
                pumpBeforeTest: (tester) async {
                  await tester.pump();
                  await tester.pump(const Duration(milliseconds: 300));
                },
                builder: () => GoldenTestScenario(
                  name: '$stateName/$variant',
                  child: _surface(
                    account,
                    themeMode: themeMode,
                    locale: locale,
                    textScale: textScale,
                    width: width,
                  ),
                ),
              ),
            );
          }
        }
      }
    }
  }
}

Widget _surface(
  GuestAccount? account, {
  required ThemeMode themeMode,
  required Locale locale,
  required double textScale,
  required double width,
}) {
  final auth = AuthCubit(
    _AccountAuthRepository(),
    signOutCoordinator: _NoopSignOut(),
  );
  if (account != null) auth.applyAccount(account);
  final settings = AppSettingsCubit.seeded(
    AppSettings(locale: locale, themeMode: themeMode),
  );
  final connectivity = FakeConnectivity().createCubit();
  return SizedBox(
    width: width,
    height: 844,
    child: MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SupportRepository>.value(
          value: FakeSupportRepository(),
        ),
        RepositoryProvider<InAppBrowser>.value(value: _NoopBrowser()),
        RepositoryProvider<AppConfigSource>.value(
          value: FakeAppConfigRepository(
            AppConfig(
              minSupportedBuildAndroid: 1,
              minSupportedBuildIos: 1,
              supportPhone: '+201000000000',
              currentTermsVersion: 'v1',
              supportContact: const SupportContact(
                phone: '+201000000000',
                hoursAr: 'يوميًا 9ص–9م',
                hoursEn: 'Daily 9am–9pm',
              ),
              legal: LegalLinks(
                termsUrlAr: Uri.parse('https://example.invalid/terms'),
                termsUrlEn: Uri.parse('https://example.invalid/terms-en'),
                privacyUrlAr: Uri.parse('https://example.invalid/privacy'),
                privacyUrlEn: Uri.parse('https://example.invalid/privacy-en'),
              ),
            ),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: auth),
          BlocProvider<AppSettingsCubit>.value(value: settings),
          BlocProvider<ConnectivityCubit>.value(value: connectivity),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: OnAirTheme.light,
          darkTheme: OnAirTheme.dark,
          themeMode: themeMode,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const AccountScreen(),
        ),
      ),
    ),
  );
}

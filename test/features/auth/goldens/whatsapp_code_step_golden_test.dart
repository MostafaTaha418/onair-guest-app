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
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/features/auth/phone_verification/presentation/phone_verification_cubit.dart';
import 'package:on_air/features/auth/phone_verification/presentation/widgets/whatsapp_code_step.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import '../../../helpers/fake_app_config_repository.dart';

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

enum _CodeState {
  counting,
  ready,
  codeError,
  notOnWhatsApp,
  attestation;

  PvCode state(DateTime now) {
    // The server window: counting keeps a 30 s wait, ready sends none.
    final window = SendWindow(
      serverTime: now,
      nextSendAt: this == _CodeState.counting
          ? now.add(const Duration(seconds: 30))
          : null,
    );
    return PvCode(
      challenge: WhatsAppChallenge(
        challengeId: 'challenge-1',
        maskedPhone: '+20 10•• ••• 678',
        expiresAt: now.add(const Duration(minutes: 10)),
        window: window,
      ),
      code: this == _CodeState.codeError ? '123456' : '',
      errorKey: this == _CodeState.codeError ? 'authOtpInvalid' : null,
      notice: switch (this) {
        _CodeState.notOnWhatsApp => PvNotice.notOnWhatsApp,
        _CodeState.attestation => PvNotice.attestationFailed,
        _ => null,
      },
    );
  }
}

/// Pumps the code step with the cubit already sitting in the requested
/// state — no timers, no races (the golden pump cannot await cubits).
Widget _step({
  required ThemeMode mode,
  required TextDirection direction,
  required double scale,
  required int width,
  required _CodeState codeState,
}) {
  final cubit = PhoneVerificationCubit(
    _StubRepository(),
    purpose: PhoneVerificationPurpose.register,
    needsName: false,
    needsTerms: false,
    locale: 'ar',
    currentTermsVersion: 'v1',
  )..emit(codeState.state(DateTime.now().toUtc()));
  return RepositoryProvider<AppConfigSource>(
    create: (_) => FakeAppConfigRepository(
      const AppConfig(
        minSupportedBuildAndroid: 1,
        minSupportedBuildIos: 1,
        supportPhone: '+201000000000',
        currentTermsVersion: 'v1',
      ),
    ),
    child: BlocProvider<PhoneVerificationCubit>.value(
      value: cubit,
      child: SizedBox(
        width: width.toDouble(),
        height: 800,
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
            ),
            child: Directionality(textDirection: direction, child: child!),
          ),
          home: Scaffold(
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(28),
                children: const [
                  WhatsAppCodeStep(supportPhone: '+201000000000'),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final (stateName, codeState) in [
    ('counting', _CodeState.counting),
    ('ready', _CodeState.ready),
    ('code_error', _CodeState.codeError),
    ('not_on_whatsapp', _CodeState.notOnWhatsApp),
    ('attestation', _CodeState.attestation),
  ]) {
    for (final (modeName, mode) in [
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ]) {
      for (final (dirName, direction) in [
        ('rtl', TextDirection.rtl),
        ('ltr', TextDirection.ltr),
      ]) {
        for (final (scaleName, scale) in [('1_0', 1.0), ('1_3', 1.3)]) {
          for (final (widthName, width) in [('320', 320), ('800', 800)]) {
            unawaited(
              goldenTest(
                'whatsapp_code_$stateName — $modeName $dirName $scaleName $widthName',
                fileName:
                    'whatsapp_code_${stateName}_${modeName}_${dirName}_${scaleName}_$widthName',
                constraints: const BoxConstraints(
                  maxWidth: 820,
                  maxHeight: 850,
                ),
                pumpBeforeTest: (tester) async {
                  await tester.pump();
                },
                builder: () => GoldenTestScenario(
                  name: '$modeName/$dirName/$scaleName/$widthName',
                  child: _step(
                    mode: mode,
                    direction: direction,
                    scale: scale,
                    width: width,
                    codeState: codeState,
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

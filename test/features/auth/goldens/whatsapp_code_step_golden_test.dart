@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/features/auth/phone_verification/presentation/phone_verification_cubit.dart';
import 'package:on_air/features/auth/phone_verification/presentation/widgets/send_window_notice.dart';
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

/// The pinned instant: the blocked state renders a real Cairo date, and a
/// live clock would diff every run (the auth_flow pattern).
final pinnedNow = DateTime.utc(2026, 11, 14, 10);

/// The frozen device clock for the countdown goldens: one real instant the
/// whole suite shares, so the text never races the second hand.
final DateTime frozenNow = DateTime.now().toUtc();

enum _CodeState {
  counting,
  countingHours,
  ready,
  codeError,
  notOnWhatsApp,
  attestation,
  blocked;

  PvState state(DateTime now) {
    // The server window: counting keeps a 30 s wait, countingHours a 23 h
    // one (the hours rendering), ready sends none (§4.2, T065). The window
    // is stamped with the REAL clock — remainingUntilSend subtracts the
    // time since receivedAt, so a pinned instant would drift the text by
    // the wall-clock distance; only the BLOCKED date stays pinned.
    final real = frozenNow;
    final window = SendWindow(
      serverTime: real,
      receivedAt: real,
      nextSendAt: switch (this) {
        _CodeState.counting => real.add(const Duration(seconds: 30)),
        _CodeState.countingHours => real.add(
          const Duration(hours: 23, minutes: 10),
        ),
        _ => null,
      },
    );
    final code = PvCode(
      challenge: WhatsAppChallenge(
        challengeId: 'challenge-1',
        maskedPhone: '+20 10•• ••• 678',
        expiresAt: real.add(const Duration(minutes: 10)),
        window: window,
      ),
      code: this == _CodeState.codeError ? '123456' : '',
      error: this == _CodeState.codeError
          ? const ApiError(
              code: ErrorCode.otpInvalid,
              messageKey: 'authOtpInvalid',
            )
          : null,
      notice: switch (this) {
        _CodeState.notOnWhatsApp => PvNotice.notOnWhatsApp,
        _CodeState.attestation => PvNotice.attestationFailed,
        _ => null,
      },
    );
    if (this == _CodeState.blocked) {
      // OTP_SEND_BLOCKED: the step renders disabled behind the notice.
      return PvBlocked(
        blockedUntil: now.add(const Duration(days: 7)),
        serverTime: now,
        code: code,
      );
    }
    return code;
  }
}

/// Pumps the code step with the cubit already sitting in the requested
/// state — no timers, no races (the golden pump cannot await cubits). The
/// blocked state adds the notice above, exactly like the screen does.
Widget _step({
  required ThemeMode mode,
  required TextDirection direction,
  required double scale,
  required int width,
  required _CodeState codeState,
}) {
  // One shared instant: the notice and the step's snapshot must show the
  // same lift date.
  final now = pinnedNow;
  final cubit = PhoneVerificationCubit(
    _StubRepository(),
    purpose: PhoneVerificationPurpose.register,
    needsName: false,
    needsTerms: false,
    locale: 'ar',
    currentTermsVersion: 'v1',
  )..emit(codeState.state(now));
  // One shared frozen clock: every scenario renders the same remaining.
  final codeStep = WhatsAppCodeStep(
    supportPhone: '+201000000000',
    clock: () => frozenNow,
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
                children: [
                  if (codeState == _CodeState.blocked) ...[
                    BlockedNotice(
                      blockedUntil: now.add(const Duration(days: 7)),
                      onSupport: () {},
                      onSignOut: () {},
                    ),
                    const SizedBox(height: 16),
                  ],
                  codeStep,
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
    ('counting_hours', _CodeState.countingHours),
    ('ready', _CodeState.ready),
    ('code_error', _CodeState.codeError),
    ('not_on_whatsapp', _CodeState.notOnWhatsApp),
    ('attestation', _CodeState.attestation),
    ('blocked', _CodeState.blocked),
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

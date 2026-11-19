@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/account/domain/deletion.dart';
import 'package:on_air/features/account/presentation/delete/delete_account_cubit.dart';
import 'package:on_air/features/account/presentation/delete/delete_account_screen.dart';
import 'package:on_air/features/account_gate/application/sign_out_service.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_connectivity.dart';

class _FakeAccountRepository extends Fake implements AccountRepository {}

class _NoopCoordinator extends Fake implements SignOutCoordinator {
  @override
  Future<void> signOut() async {}
}

class _SignedInRepository extends Fake implements AuthRepository {
  @override
  Future<GuestAccount?> restoreSession() async => null;
  @override
  Stream<GuestAccount?> get authStateChanges => const Stream.empty();
}

void main() {
  final states = <(String, DeletionState)>[
    ('explain', const DeletionExplain()),
    (
      'blocked',
      const DeletionBlocked([
        DeletionBlocker(
          kind: DeletionBlockerKind.booking,
          id: 'b-1',
          code: 'OA-2042',
        ),
        DeletionBlocker(
          kind: DeletionBlockerKind.refund,
          id: 'b-2',
          code: 'OA-2050',
        ),
      ]),
    ),
    (
      'code_step',
      DeletionCodeStep(
        challengeId: 'challenge-1',
        maskedEmail: 'g***@e***.com',
        window: SendWindow(
          serverTime: DateTime.utc(2026, 11, 17, 12),
          receivedAt: DateTime.utc(2026, 11, 17, 12),
          nextSendAt: DateTime.utc(2026, 11, 17, 12, 1),
        ),
      ),
    ),
  ];

  for (final (stateName, state) in states) {
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
                'delete account — $stateName $variant',
                fileName: 'delete_account_${stateName}_$variant',
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
                    state,
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
  DeletionState state, {
  required ThemeMode themeMode,
  required Locale locale,
  required double textScale,
  required double width,
}) {
  final connectivity = FakeConnectivity().createCubit();
  final auth = AuthCubit(
    _SignedInRepository(),
    signOutCoordinator: _NoopCoordinator(),
  );
  final cubit = DeleteAccountCubit.seeded(
    repository: _FakeAccountRepository(),
    auth: auth,
    state: state,
  );
  return SizedBox(
    width: width,
    height: 844,
    child: BlocProvider<ConnectivityCubit>.value(
      value: connectivity,
      child: BlocProvider<DeleteAccountCubit>.value(
        value: cubit,
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
          home: const DeleteAccountScreen(),
        ),
      ),
    ),
  );
}

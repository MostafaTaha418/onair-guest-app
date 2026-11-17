import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/account/presentation/edit_name_sheet.dart';
import 'package:on_air/features/account_gate/application/sign_out_service.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/support/domain/support_repository.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_support_repository.dart';

class _FakeAccountRepository extends Fake implements AccountRepository {
  int saveCalls = 0;
  String? savedName;
  Exception? nextError;
  void Function(String name)? onSave;

  @override
  Future<void> updateProfile({String? fullName, String? locale}) async {
    saveCalls++;
    if (nextError case final error?) throw error;
    savedName = fullName?.trim();
    if (savedName case final name?) onSave?.call(name);
  }
}

class _NoopCoordinator extends Fake implements SignOutCoordinator {
  @override
  Future<void> signOut() async {}
}

class _SignedInRepository extends Fake implements AuthRepository {
  _SignedInRepository(this.account);
  GuestAccount account;

  @override
  Future<GuestAccount?> restoreSession() async => account;

  @override
  Future<GuestAccount?> refreshAccount() async => account;

  @override
  Stream<GuestAccount?> get authStateChanges => const Stream.empty();

  void rename(String name) {
    account = GuestAccount(
      id: account.id,
      status: account.status,
      phone: account.phone,
      phoneVerified: account.phoneVerified,
      email: account.email,
      emailVerified: account.emailVerified,
      fullName: name,
      authProviders: account.authProviders,
      hasPassword: account.hasPassword,
      acceptedTermsVersion: account.acceptedTermsVersion,
      acceptedTermsAt: account.acceptedTermsAt,
    );
  }
}

void main() {
  late AppLocalizations l10n;
  late _FakeAccountRepository repository;
  late FakeConnectivity connectivity;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() {
    repository = _FakeAccountRepository();
    connectivity = FakeConnectivity();
  });

  tearDown(() => connectivity.dispose());

  (AuthCubit, _SignedInRepository) authCubit() {
    final source = _SignedInRepository(
      GuestAccount(
        id: 'id',
        status: AccountStatus.active,
        phone: '+201012345678',
        fullName: 'الاسم القديم',
        email: 'legacy@onair.test',
        emailVerified: true,
        acceptedTermsVersion: 'v1',
      ),
    );
    return (
      AuthCubit(source, signOutCoordinator: _NoopCoordinator()),
      source,
    );
  }

  Future<void> pump(WidgetTester tester) async {
    final connectivityCubit = connectivity.createCubit();
    addTearDown(connectivityCubit.close);
    final (auth, source) = authCubit();
    repository.onSave = source.rename;
    await auth.restore();
    addTearDown(auth.close);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AccountRepository>.value(value: repository),
          RepositoryProvider<SupportRepository>.value(
            value: FakeSupportRepository(),
          ),
        ],
        child: BlocProvider<AuthCubit>.value(
          value: auth,
          child: BlocProvider<ConnectivityCubit>.value(
            value: connectivityCubit,
            child: MaterialApp(
              locale: const Locale('ar'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              theme: OnAirTheme.light,
              home: Scaffold(
                body: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final account = state is SignedIn ? state.account : null;
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (account != null) ...[
                            Text(account.fullName ?? ''),
                            Text(account.initials),
                          ],
                          Builder(
                            builder: (context) => TextButton(
                              onPressed: () => showEditNameSheet(
                                context,
                                currentName: account?.fullName ?? '',
                              ),
                              child: const Text('open'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the name validates live: 2-80 after trim', (tester) async {
    await pump(tester);
    final save = find.byKey(const ValueKey('edit-name-save'));
    // The pre-filled valid name keeps save enabled.
    expect(tester.widget<OnAirPrimaryButton>(save).onPressed, isNotNull);
    await tester.enterText(
      find.byKey(const ValueKey('edit-name-field')),
      'ا',
    );
    await tester.pump();
    expect(find.text(l10n.accountNameInvalid), findsOneWidget);
    expect(tester.widget<OnAirPrimaryButton>(save).onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('edit-name-field')),
      List.filled(81, 'x').join(),
    );
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      hasLength(80),
    );
    expect(tester.widget<OnAirPrimaryButton>(save).onPressed, isNotNull);
  });

  testWidgets('a double tap saves once and pops on success', (tester) async {
    await pump(tester);
    final save = find.byKey(const ValueKey('edit-name-save'));
    await tester.enterText(
      find.byKey(const ValueKey('edit-name-field')),
      'الاسم الجديد',
    );
    await tester.pump();
    tester.widget<OnAirPrimaryButton>(save).onPressed!();
    tester.widget<OnAirPrimaryButton>(save).onPressed!();
    await tester.pumpAndSettle();
    expect(repository.saveCalls, 1);
    expect(repository.savedName, 'الاسم الجديد');
    expect(find.byKey(const ValueKey('edit-name-field')), findsNothing);
    expect(find.text('الاسم الجديد'), findsOneWidget);
    expect(find.text('اا'), findsOneWidget);
  });

  testWidgets('the sheet stays visible above the keyboard', (tester) async {
    await pump(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(() => tester.view.viewInsets = FakeViewPadding.zero);
    await tester.pump();
    expect(find.byKey(const ValueKey('edit-name-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-name-save')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failure keeps the sheet open with the message', (
    tester,
  ) async {
    repository.nextError = const AppFailure(
      ApiError(
        code: ErrorCode.validationFailed,
        messageKey: 'errorValidationFailed',
      ),
    );
    await pump(tester);
    await tester.enterText(
      find.byKey(const ValueKey('edit-name-field')),
      'الاسم الجديد',
    );
    await tester.pump();
    tester
        .widget<OnAirPrimaryButton>(
          find.byKey(const ValueKey('edit-name-save')),
        )
        .onPressed!();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-name-field')), findsOneWidget);
    expect(find.text(l10n.errorValidationFailed), findsOneWidget);
    expect(repository.saveCalls, 1);
  });
}

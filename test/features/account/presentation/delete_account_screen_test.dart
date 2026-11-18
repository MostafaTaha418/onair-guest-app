import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/account/domain/deletion.dart';
import 'package:on_air/features/account/presentation/delete/delete_account_cubit.dart';
import 'package:on_air/features/account/presentation/delete/delete_account_screen.dart';
import 'package:on_air/features/account_gate/application/sign_out_service.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_connectivity.dart';

class _FakeAccountRepository extends Fake implements AccountRepository {
  DeletionBlockedException? nextRequestBlocker;
  Exception? nextRequestError;
  Exception? nextConfirmError;

  @override
  Future<DeletionRequest> requestDeletion() async {
    if (nextRequestBlocker case final blocker?) throw blocker;
    if (nextRequestError case final error?) throw error;
    return const DeletionRequest(
      challengeId: 'challenge-1',
      maskedEmail: 'g***@e***.com',
    );
  }

  @override
  Future<SendWindow> sendDeletionCode(String challengeId) async {
    // Relative to the real clock: the screen computes the countdown from
    // `DateTime.now()`, so a fixed date goes stale at wall-clock noon.
    final now = DateTime.now().toUtc();
    return SendWindow(
      serverTime: now,
      receivedAt: now,
      nextSendAt: now.add(const Duration(minutes: 1)),
    );
  }

  @override
  Future<void> confirmDeletion(String challengeId, String code) async {
    if (nextConfirmError case final error?) throw error;
  }
}

class _NoopCoordinator extends Fake implements SignOutCoordinator {
  int calls = 0;
  @override
  Future<void> signOut() async => calls++;
}

void main() {
  late AppLocalizations l10n;
  late FakeConnectivity connectivity;
  late _FakeAccountRepository repository;
  late _NoopCoordinator coordinator;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() {
    connectivity = FakeConnectivity();
    repository = _FakeAccountRepository();
    coordinator = _NoopCoordinator();
  });

  tearDown(() => connectivity.dispose());

  Future<void> pump(WidgetTester tester) async {
    final connectivityCubit = connectivity.createCubit();
    addTearDown(connectivityCubit.close);
    final account = GuestAccount(
      id: 'id',
      status: AccountStatus.active,
      phone: '+201012345678',
      acceptedTermsVersion: 'v1',
    );
    final auth = AuthCubit(
      _SignedInRepository(account),
      signOutCoordinator: coordinator,
    );
    await auth.restore();
    addTearDown(auth.close);
    final router = GoRouter(
      initialLocation: AppRoutes.accountDelete,
      routes: [
        GoRoute(
          path: AppRoutes.accountDelete,
          builder: (context, _) => BlocProvider<DeleteAccountCubit>(
            create: (context) => DeleteAccountCubit(
              repository: repository,
              auth: context.read<AuthCubit>(),
            ),
            child: const DeleteAccountScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.bookingDetailsPattern,
          name: 'booking-details',
          builder: (_, state) => Text('booking:${state.pathParameters['id']}'),
        ),
        GoRoute(
          path: AppRoutes.support,
          builder: (_, _) => const Text('support'),
        ),
        GoRoute(path: AppRoutes.home, builder: (_, _) => const Text('home')),
      ],
    );
    // Pin a tall window so every step of the flow stays hit-testable.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: auth,
        child: BlocProvider<ConnectivityCubit>.value(
          value: connectivityCubit,
          child: MaterialApp.router(
            locale: const Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: OnAirTheme.light,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> reachCodeStep(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('delete-understand')));
    await tester.pump();
    await tester.tap(find.text(l10n.deleteCta));
    await tester.pumpAndSettle();
    // The confirm sheet guards the arming.
    await tester.tap(find.text(l10n.deleteUnderstand).last);
    await tester.pumpAndSettle();
    await tester.pump();
  }

  testWidgets('the three bullets and the finality checkbox render', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(l10n.deleteWhatGoes), findsOneWidget);
    expect(find.text(l10n.deleteWhatStays), findsOneWidget);
    expect(find.text(l10n.deleteFinal), findsOneWidget);
    expect(find.text(l10n.deleteUnderstand), findsOneWidget);
  });

  testWidgets('«احذف حسابي» stays disabled until the box is checked', (
    tester,
  ) async {
    await pump(tester);
    final button = find.ancestor(
      of: find.text(l10n.deleteCta),
      matching: find.byType(TextButton),
    );
    expect(tester.widget<TextButton>(button).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('delete-understand')));
    await tester.pump();
    expect(tester.widget<TextButton>(button).onPressed, isNotNull);
  });

  testWidgets('the blocked view lists blockers that tap to the booking', (
    tester,
  ) async {
    repository.nextRequestBlocker = const DeletionBlockedException([
      DeletionBlocker(
        kind: DeletionBlockerKind.booking,
        id: 'b-blocked',
        code: 'OA-BLOCKED',
      ),
      DeletionBlocker(
        kind: DeletionBlockerKind.other,
        id: '',
        code: 'OA-OTHER',
      ),
    ]);
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('delete-understand')));
    await tester.pump();
    await tester.tap(find.text(l10n.deleteCta));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.deleteUnderstand).last);
    await tester.pumpAndSettle();
    await tester.pump();
    expect(find.text(l10n.deleteBlockedTitle), findsOneWidget);
    expect(find.text(l10n.deleteBlockerBooking('OA-BLOCKED')), findsOneWidget);
    // The unknown kind is still listed, by its raw code.
    expect(find.text('OA-OTHER'), findsOneWidget);
    await tester.tap(find.text(l10n.deleteBlockerBooking('OA-BLOCKED')));
    await tester.pumpAndSettle();
    expect(find.text('booking:b-blocked'), findsOneWidget);
  });

  testWidgets('the code step uses the OTP field with the resend countdown', (
    tester,
  ) async {
    await pump(tester);
    await reachCodeStep(tester);
    expect(find.text(l10n.deleteCodeSent('g***@e***.com')), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-otp-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-resend')), findsOneWidget);
    // The resend is still waiting on the server window.
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey('delete-resend')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('offline disables the danger actions', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('delete-understand')));
    await tester.pump();
    connectivity.goOffline();
    await tester.pump();
    final button = find.ancestor(
      of: find.text(l10n.deleteCta),
      matching: find.byType(TextButton),
    );
    expect(tester.widget<TextButton>(button).onPressed, isNull);
  });

  testWidgets('a wrong code shows the email-code message and keeps the step', (
    tester,
  ) async {
    repository.nextConfirmError = const AppFailure(
      ApiError(code: ErrorCode.otpInvalid, messageKey: 'authOtpInvalid'),
    );
    await pump(tester);
    await reachCodeStep(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('delete-otp-field')),
        matching: find.byType(TextField),
      ),
      '000000',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('delete-confirm')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.authOtpInvalid), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-otp-field')), findsOneWidget);
  });

  testWidgets('the right code navigates home as a visitor', (tester) async {
    await pump(tester);
    await reachCodeStep(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('delete-otp-field')),
        matching: find.byType(TextField),
      ),
      MockBackend.verificationCode,
    );
    // Six digits complete the field: the confirm fires on its own.
    await tester.pumpAndSettle();
    expect(coordinator.calls, 1);
    expect(find.text('home'), findsOneWidget);
  });
}

/// The signed-in seam: one account restored on session read.
class _SignedInRepository extends Fake implements AuthRepository {
  _SignedInRepository(this.account);
  final GuestAccount account;

  @override
  Future<GuestAccount?> restoreSession() async => account;

  @override
  Stream<GuestAccount?> get authStateChanges => const Stream.empty();
}

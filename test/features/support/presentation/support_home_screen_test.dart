import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/features/support/presentation/home/support_home_cubit.dart';
import 'package:on_air/features/support/presentation/home/support_home_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_support_repository.dart';

void main() {
  late AppLocalizations l10n;
  late FakeConnectivity connectivity;
  late FakeSupportRepository repository;
  late ControllableNotificationSignalSource signals;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() {
    connectivity = FakeConnectivity();
    repository = FakeSupportRepository();
    signals = ControllableNotificationSignalSource();
  });

  tearDown(() => connectivity.dispose());

  Future<SupportHomeCubit> pump(WidgetTester tester) async {
    final connectivityCubit = connectivity.createCubit();
    final cubit = SupportHomeCubit(
      repository: repository,
      signals: signals,
      connection: connectivityCubit,
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider.value(value: connectivityCubit),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: OnAirTheme.light,
          home: const SupportHomeScreen(),
        ),
      ),
    );
    addTearDown(cubit.close);
    addTearDown(connectivityCubit.close);
    return cubit;
  }

  testWidgets('shows skeleton then an empty state', (tester) async {
    repository.pages.add(const CasePage(items: [], nextCursor: null));
    final cubit = await pump(tester);
    expect(find.byType(LoadingView), findsOneWidget);
    await cubit.load();
    await tester.pump();
    expect(find.text(l10n.supportEmpty), findsOneWidget);
  });

  testWidgets('error renders its request reference', (tester) async {
    repository.nextError = const AppFailure(
      ApiError(
        code: ErrorCode.internal,
        messageKey: 'internal',
        requestId: 'req-support',
      ),
    );
    final cubit = await pump(tester);
    await cubit.load();
    await tester.pump();
    expect(find.textContaining('req-support'), findsOneWidget);
  });

  testWidgets('success separates open and finished cases', (tester) async {
    repository.pages.add(
      CasePage(
        items: [
          sampleSupportCase(),
          sampleSupportCase(
            id: 'c0000000-0000-4000-8000-000000000002',
            status: CaseStatus.closed,
          ),
        ],
        nextCursor: null,
      ),
    );
    final cubit = await pump(tester);
    await cubit.load();
    await tester.pump();
    expect(find.text(l10n.supportFinishedCases), findsOneWidget);
    expect(find.textContaining('SC-1042'), findsNWidgets(2));
  });

  testWidgets('offline keeps the list and displays the banner', (tester) async {
    repository.pages.add(
      CasePage(items: [sampleSupportCase()], nextCursor: null),
    );
    final cubit = await pump(tester);
    await cubit.load();
    connectivity.goOffline();
    await tester.pump();
    expect(find.byType(OfflineBanner), findsOneWidget);
    expect(find.textContaining('SC-1042'), findsOneWidget);
  });
}

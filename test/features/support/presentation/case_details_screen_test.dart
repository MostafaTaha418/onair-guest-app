import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/files/attachment_picker.dart';
import 'package:on_air/core/files/image_sanitizer.dart';
import 'package:on_air/core/files/private_file_uploader.dart';
import 'package:on_air/design_system/components/message_bubble.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/support/data/mock_support_server.dart';
import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/features/support/presentation/case/case_details_cubit.dart';
import 'package:on_air/features/support/presentation/case/case_details_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_support_files.dart';
import '../../../helpers/fake_support_repository.dart';

void main() {
  late AppLocalizations l10n;
  late FakeConnectivity connectivity;
  late FakeSupportRepository repository;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() {
    connectivity = FakeConnectivity();
    repository = FakeSupportRepository();
  });

  tearDown(() => connectivity.dispose());

  Future<void> pump(WidgetTester tester) async {
    final connectivityCubit = connectivity.createCubit();
    addTearDown(connectivityCubit.close);
    final router = GoRouter(
      initialLocation: '/case/${sampleSupportCase().id}',
      routes: [
        GoRoute(
          path: '/case/:id',
          builder: (context, state) => BlocProvider(
            create: (_) {
              final cubit = CaseDetailsCubit(
                caseId: state.pathParameters['id']!,
                repository: repository,
              );
              unawaited(cubit.load());
              return cubit;
            },
            child: CaseDetailsScreen(caseId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/support/new',
          builder: (_, state) => Text('new:${state.uri}'),
        ),
        GoRoute(
          path: '/support',
          builder: (_, _) => const Text('support-home'),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AttachmentPicker>.value(
            value: const EmptyAttachmentPicker(),
          ),
          RepositoryProvider<ImageSanitizer>.value(
            value: fakeSupportSanitizer(),
          ),
          RepositoryProvider<PrivateFileUploader>.value(
            value: fakeSupportUploader,
          ),
          RepositoryProvider<MockSupportServer?>.value(
            value: MockSupportServer(latency: Duration.zero),
          ),
        ],
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
  }

  testWidgets('shows loading then conversation success', (tester) async {
    await pump(tester);
    expect(find.byType(LoadingView), findsOneWidget);
    await tester.pump();
    expect(find.byType(MessageBubble), findsOneWidget);
    expect(find.text('SC-1042'), findsOneWidget);
  });

  testWidgets('resolved notice appears above the composer', (tester) async {
    repository.detailPages.add(sampleDetails(status: CaseStatus.resolved));
    await pump(tester);
    await tester.pump();
    expect(find.text(l10n.supportResolvedNotice), findsOneWidget);
  });

  testWidgets('closed notice opens a new linked case', (tester) async {
    repository.detailPages.add(sampleDetails(status: CaseStatus.closed));
    await pump(tester);
    await tester.pump();
    expect(find.text(l10n.supportCaseClosed), findsOneWidget);
    await tester.tap(find.text(l10n.supportOpenNewCase));
    await tester.pumpAndSettle();
    expect(find.textContaining('booking='), findsOneWidget);
  });

  testWidgets('not found stays neutral and returns to support', (tester) async {
    repository.nextError = const AppFailure(
      ApiError(code: ErrorCode.notFound, messageKey: 'notFound'),
    );
    await pump(tester);
    await tester.pump();
    expect(find.text(l10n.supportCaseNotFound), findsOneWidget);
    expect(find.text(l10n.supportBackToSupport), findsOneWidget);
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/files/attachment_picker.dart';
import 'package:on_air/core/files/image_sanitizer.dart';
import 'package:on_air/core/files/private_file_uploader.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/app_update/presentation/not_available_screen.dart';
import 'package:on_air/features/support/data/mock_support_server.dart';
import 'package:on_air/features/support/domain/support_repository.dart';
import 'package:on_air/features/support/presentation/case/case_details_cubit.dart';
import 'package:on_air/features/support/presentation/case/case_details_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_support_files.dart';

void main() {
  testWidgets('foreign and malformed case links reveal no case data', (
    tester,
  ) async {
    final server = MockSupportServer(latency: Duration.zero);
    final connectivity = FakeConnectivity();
    final connectivityCubit = connectivity.createCubit();
    addTearDown(connectivity.dispose);
    addTearDown(connectivityCubit.close);
    final router = GoRouter(
      initialLocation: AppRoutes.supportCase(MockSupportServer.foreignCaseId),
      routes: [
        GoRoute(
          path: AppRoutes.supportCasePattern,
          builder: (context, state) {
            final id = state.pathParameters['caseId']!;
            if (!AppRoutes.isUuidV4(id)) return const NotAvailableScreen();
            return BlocProvider(
              create: (_) {
                final cubit = CaseDetailsCubit(
                  caseId: id,
                  repository: server,
                );
                unawaited(cubit.load());
                return cubit;
              },
              child: CaseDetailsScreen(caseId: id),
            );
          },
        ),
      ],
    );
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<SupportRepository>.value(value: server),
          RepositoryProvider<MockSupportServer?>.value(value: server),
          RepositoryProvider<AttachmentPicker>.value(
            value: const EmptyAttachmentPicker(),
          ),
          RepositoryProvider<ImageSanitizer>.value(
            value: fakeSupportSanitizer(),
          ),
          RepositoryProvider<PrivateFileUploader>.value(
            value: fakeSupportUploader,
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
    await tester.pumpAndSettle();
    expect(find.textContaining('INTERNAL'), findsNothing);
    expect(find.textContaining('SC-'), findsNothing);
    expect(server.getCalls, 1);

    router.go('/support/not-a-uuid');
    await tester.pumpAndSettle();
    expect(find.textContaining('SC-'), findsNothing);
    expect(server.getCalls, 1);
  });
}

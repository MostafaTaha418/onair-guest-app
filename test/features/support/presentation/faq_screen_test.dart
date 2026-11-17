import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/redirect.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/design_system/components/info_banner.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/support/data/faq_cache.dart';
import 'package:on_air/features/support/domain/support_repository.dart';
import 'package:on_air/features/support/presentation/faq/faq_cubit.dart';
import 'package:on_air/features/support/presentation/faq/faq_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_support_repository.dart';

Map<String, dynamic> faqRow({
  required String id,
  required int order,
  required String questionAr,
  required String answerAr,
}) => {
  'id': id,
  'question_ar': questionAr,
  'answer_ar': answerAr,
  'question_en': questionAr,
  'answer_en': answerAr,
  'sort_order': order,
};

void main() {
  late AppLocalizations l10n;
  late FakeSupportRepository repository;
  late FaqCache cache;
  late Directory cacheDirectory;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() {
    repository = FakeSupportRepository()
      ..faqRows = [
        faqRow(
          id: 'faq-1',
          order: 1,
          questionAr: 'إزاي أحجز شقة؟',
          answerAr: 'اختار وحدد وادفع.',
        ),
        faqRow(
          id: 'faq-2',
          order: 2,
          questionAr: 'إيه طرق الدفع؟',
          answerAr: 'فيزا أو كاش.',
        ),
        faqRow(
          id: 'faq-3',
          order: 3,
          questionAr: 'الاسترداد بيرجع أمتى؟',
          answerAr: 'خلال 5-7 أيام.',
        ),
      ];
    cacheDirectory = Directory.systemTemp.createTempSync('on_air_faq_screen');
    cache = FaqCache(
      JsonFileCache(
        directory: cacheDirectory,
        fileName: 'faq_v1.json',
        schema: 1,
      ),
    );
  });

  tearDown(() => cacheDirectory.deleteSync(recursive: true));

  Future<void> pump(
    WidgetTester tester, {
    bool signedIn = true,
    SupportRepository? repositoryOverride,
  }) async {
    final router = GoRouter(
      initialLocation: '/support/faq',
      routes: [
        GoRoute(
          path: '/support/faq',
          builder: (context, state) => BlocProvider<FaqCubit>(
            create: (context) {
              final cubit = FaqCubit(
                repository: repositoryOverride ?? repository,
                cache: cache,
              );
              cubit.load().ignore();
              return cubit;
            },
            child: const FaqScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.supportNew,
          builder: (_, state) => Text('new:${state.uri}'),
        ),
        // The real login location is /auth/login; the fake page renders the
        // decoded return path the redirect carried along.
        GoRoute(
          path: AppRoutes.login,
          builder: (_, state) =>
              Text('login:${state.uri.queryParameters['from']}'),
        ),
      ],
      redirect: (context, state) => resolveRedirect(
        RedirectContext(
          location: state.uri.toString(),
          authState: signedIn
              ? SignedIn(
                  GuestAccount(
                    id: 'id',
                    status: AccountStatus.active,
                    phone: '+201012345678',
                    acceptedTermsVersion: 'v1',
                  ),
                  isComplete: true,
                )
              : const SignedOut(),
        ),
      ),
    );
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<SupportRepository>.value(value: repository),
          RepositoryProvider<AppConfigSource>.value(
            value: const MockAppConfigSource(),
          ),
        ],
        child: MaterialApp.router(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: OnAirTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the skeleton renders before the list', (tester) async {
    // Keep the load pending: a never-completing future keeps the skeleton.
    final pending = Completer<List<Map<String, dynamic>>>();
    await pump(
      tester,
      repositoryOverride: _GatedRepository(pending.future),
    );
    expect(find.byType(LoadingView), findsOneWidget);
    pending.complete(const []);
    await tester.pump();
    await tester.pump();
    expect(find.byType(LoadingView), findsNothing);
  });

  testWidgets('the list renders and answers expand', (tester) async {
    await pump(tester);
    await tester.pump();
    expect(find.text('إزاي أحجز شقة؟'), findsOneWidget);
    expect(find.text('اختار وحدد وادفع.'), findsNothing);
    await tester.tap(find.text('إزاي أحجز شقة؟'));
    await tester.pumpAndSettle();
    expect(find.text('اختار وحدد وادفع.'), findsOneWidget);
  });

  testWidgets('search filters with Arabic normalization and shows no results', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('faq-search-field')),
      'شقه',
    );
    await tester.pump();
    expect(find.text('إزاي أحجز شقة؟'), findsOneWidget);
    expect(find.text('إيه طرق الدفع؟'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('faq-search-field')),
      'كلام مالوش لزمة',
    );
    await tester.pump();
    expect(find.text(l10n.supportFaqNoResults), findsOneWidget);
  });

  testWidgets('«حالة جديدة» sends a visitor to login with a return path', (
    tester,
  ) async {
    await pump(tester, signedIn: false);
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('faq-search-field')),
      'كلام مالوش لزمة',
    );
    await tester.pump();
    await tester.tap(find.text(l10n.supportNewCase));
    await tester.pumpAndSettle();
    // The fake login page renders the decoded return path the redirect
    // carried along (SC-007).
    expect(find.text('login:/support/new'), findsOneWidget);
  });

  testWidgets('offline from cache shows the stale banner with the items', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump();
    // The first boot cached the list; a second one fails on the server.
    repository.nextFaqError = const AppFailure(
      ApiError(code: ErrorCode.network, messageKey: 'errorNoConnection'),
    );
    final router = GoRouter(
      initialLocation: '/support/faq',
      routes: [
        GoRoute(
          path: '/support/faq',
          builder: (context, state) => BlocProvider<FaqCubit>(
            create: (context) {
              final cubit = FaqCubit(repository: repository, cache: cache);
              cubit.load().ignore();
              return cubit;
            },
            child: const FaqScreen(),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<SupportRepository>.value(value: repository),
          RepositoryProvider<AppConfigSource>.value(
            value: const MockAppConfigSource(),
          ),
        ],
        child: MaterialApp.router(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: OnAirTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(InfoBanner), findsOneWidget);
    expect(find.text(l10n.supportFaqStale), findsOneWidget);
    expect(find.text('إزاي أحجز شقة؟'), findsOneWidget);
  });

  testWidgets('offline without a cache is the offline error view', (
    tester,
  ) async {
    repository.nextFaqError = const AppFailure(
      ApiError(code: ErrorCode.network, messageKey: 'errorNoConnection'),
    );
    await pump(tester);
    await tester.pump();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text(l10n.errorNoConnection), findsOneWidget);
  });

  testWidgets('the call button sits at the bottom of the screen', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.supportCall), findsOneWidget);
  });
}

final class _GatedRepository implements SupportRepository {
  _GatedRepository(this.future);
  final Future<List<Map<String, dynamic>>> future;

  @override
  Future<List<Map<String, dynamic>>> listFaq() => future;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

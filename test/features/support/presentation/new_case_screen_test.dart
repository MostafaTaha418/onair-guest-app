import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/files/attachment_picker.dart';
import 'package:on_air/core/files/image_sanitizer.dart';
import 'package:on_air/core/files/private_file_uploader.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/support/domain/support_repository.dart';
import 'package:on_air/features/support/presentation/new_case/new_case_cubit.dart';
import 'package:on_air/features/support/presentation/new_case/new_case_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_bookings_repository.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_support_files.dart';
import '../../../helpers/fake_support_repository.dart';

void main() {
  const bookingId = 'b0000000-0000-4000-8000-000000000021';

  late AppLocalizations l10n;
  late FakeConnectivity connectivity;
  late FakeSupportRepository repository;
  late FakeBookingsRepository bookings;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() {
    connectivity = FakeConnectivity();
    repository = FakeSupportRepository();
    bookings = FakeBookingsRepository()
      ..bookings[bookingId] = sampleBookingDetails()
      ..pages[BookingTab.current] = [
        sampleBookingSummary(),
        sampleBookingSummary(
          id: 'b0000000-0000-4000-8000-000000000022',
          code: 'OA-2050',
        ),
      ];
  });

  tearDown(() => connectivity.dispose());

  Future<void> pump(
    WidgetTester tester, {
    String booking = '',
    String property = '',
  }) async {
    final connectivityCubit = connectivity.createCubit();
    addTearDown(connectivityCubit.close);
    // The new-case route always sits on top of another page in the real app;
    // push it from a fake home so pop and pushReplacement are observable.
    final target =
        '/support/new'
        '${booking.isEmpty ? '' : '?booking=$booking'}'
        '${property.isEmpty ? '' : '${booking.isEmpty ? '?' : '&'}property=$property'}';
    late final GoRouter router;
    router = GoRouter(
      initialLocation: '/support',
      routes: [
        GoRoute(
          path: '/support',
          builder: (_, _) => TextButton(
            onPressed: () => router.push(target),
            child: const Text('home'),
          ),
        ),
        GoRoute(
          path: '/support/new',
          builder: (context, state) => BlocProvider<NewCaseCubit>(
            create: (context) {
              final cubit =
                  NewCaseCubit(
                    repository: repository,
                    bookings: bookings,
                    resolvePropertyTitle: (propertyId) async => 'شقة الساحل',
                    connection: connectivityCubit,
                  )..open(
                    bookingId: state.uri.queryParameters['booking'],
                    propertyId: state.uri.queryParameters['property'],
                  );
              return cubit;
            },
            child: const NewCaseScreen(),
          ),
        ),
        GoRoute(
          path: '/support/:id',
          // A Scaffold is required: the created snackbar is presented on the
          // destination screen after the form route is replaced.
          builder: (_, state) => Scaffold(
            body: Text('case:${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<SupportRepository>.value(value: repository),
          RepositoryProvider<BookingsRepository>.value(value: bookings),
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
    await tester.pump();
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
  }

  OnAirPrimaryButton sendButton(WidgetTester tester) =>
      tester.widget<OnAirPrimaryButton>(find.byType(OnAirPrimaryButton));

  Future<void> fillValidForm(WidgetTester tester) async {
    // «دفع» is not preselected by any entry point, so tapping it always
    // selects rather than deselecting the booking entry's «حجز».
    await tester.tap(find.text(l10n.supportTypePayment));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'الوصف طويل بما يكفي');
    await tester.pump();
  }

  testWidgets('the type chips are required before sending', (tester) async {
    await pump(tester);
    expect(sendButton(tester).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'الوصف طويل بما يكفي');
    await tester.pump();
    // A body alone is not enough: the type is required.
    expect(sendButton(tester).onPressed, isNull);
    await tester.tap(find.text(l10n.supportTypeBooking));
    await tester.pump();
    expect(sendButton(tester).onPressed, isNotNull);
  });

  testWidgets('the counter shows n/4000 and the too-short message', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'قصير');
    await tester.pump();
    expect(find.text('4/4000'), findsOneWidget);
    expect(find.text(l10n.supportDescriptionTooShort), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'الوصف طويل بما يكفي');
    await tester.pump();
    expect(find.text(l10n.supportDescriptionTooShort), findsNothing);
  });

  testWidgets('a booking entry shows a removable linked chip', (tester) async {
    await pump(tester, booking: bookingId);
    await tester.pump();
    expect(find.text(l10n.supportLinkedBooking('OA-2042')), findsOneWidget);
    expect(find.text(l10n.supportLinkBooking), findsNothing);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.text(l10n.supportLinkedBooking('OA-2042')), findsNothing);
    expect(find.text(l10n.supportLinkBooking), findsOneWidget);
  });

  testWidgets('linking from the sheet lists the guest bookings', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text(l10n.supportLinkBooking));
    await tester.pumpAndSettle();
    expect(find.text('OA-2042'), findsOneWidget);
    expect(find.text('OA-2050'), findsOneWidget);
    expect(find.textContaining('ديسمبر'), findsNWidgets(2));
    await tester.tap(find.text('OA-2042'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.supportLinkedBooking('OA-2042')), findsOneWidget);
    expect(find.text(l10n.supportLinkBooking), findsNothing);
  });

  testWidgets('back with content asks before discarding', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'الوصف طويل بما يكفي');
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.supportDiscardTitle), findsOneWidget);
    // «سيبها» leaves; «كمّل» stays (checked in the keep variant below).
    await tester.tap(find.text(l10n.supportDiscard));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('«كمّل» keeps editing', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'الوصف طويل بما يكفي');
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.supportKeepEditing));
    await tester.pumpAndSettle();
    expect(find.text(l10n.supportNewCase), findsOneWidget);
    expect(find.text('الوصف طويل بما يكفي'), findsOneWidget);
  });

  testWidgets('offline disables send and shows the banner', (tester) async {
    await pump(tester);
    await fillValidForm(tester);
    expect(sendButton(tester).onPressed, isNotNull);
    connectivity.goOffline();
    await tester.pump();
    expect(find.byType(OfflineBanner), findsOneWidget);
    expect(sendButton(tester).onPressed, isNull);
  });

  testWidgets('success replaces the form with the case and a snackbar', (
    tester,
  ) async {
    repository.createResult = const CreatedCase(
      caseId: 'c-new',
      code: 'SC-2001',
    );
    await pump(tester, booking: bookingId);
    await fillValidForm(tester);
    expect(sendButton(tester).onPressed, isNotNull);
    await tester.tap(find.byType(OnAirPrimaryButton));
    // A full pumpAndSettle would run through the snackbar's own timer; two
    // short pumps leave it visible while the case page is in place.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('case:c-new'), findsOneWidget);
    expect(find.text(l10n.supportCreated('SC-2001')), findsOneWidget);
  });

  testWidgets('a submission failure shows the message and keeps the form', (
    tester,
  ) async {
    repository.nextCreateError = const AppFailure(
      ApiError(code: ErrorCode.network, messageKey: 'errorNoConnection'),
    );
    await pump(tester, booking: bookingId);
    await fillValidForm(tester);
    await tester.tap(find.byType(OnAirPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.errorNoConnection), findsOneWidget);
    expect(find.textContaining('booking=$bookingId'), findsNothing);
    expect(find.text(l10n.supportLinkedBooking('OA-2042')), findsOneWidget);
  });
}

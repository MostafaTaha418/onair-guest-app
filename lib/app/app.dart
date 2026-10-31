import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/app_router.dart';
import 'package:on_air/app/router/auth_router_refresh.dart';
import 'package:on_air/app/router/incoming_links.dart';
import 'package:on_air/app/router/link_parser.dart';
import 'package:on_air/app/router/notification_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/config/version_gate.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/payments/in_app_browser.dart';
import 'package:on_air/core/push/push_messages.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/account_gate/application/device_registration_service.dart';
import 'package:on_air/features/account_gate/application/personal_data_resetter.dart';
import 'package:on_air/features/account_gate/application/sign_out_service.dart';
import 'package:on_air/features/account_gate/presentation/session_listener.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/booking/data/mock_in_app_browser.dart';
import 'package:on_air/features/booking/data/payment_attempt_store.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/booking/presentation/payment_attempt_cubit.dart';
import 'package:on_air/features/bookings/data/mock_booking_server.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/notifications/domain/notifications_repository.dart';
import 'package:on_air/features/notifications/presentation/in_app_notification_banner.dart';
import 'package:on_air/features/notifications/presentation/unread_count_cubit.dart';
import 'package:on_air/features/search/domain/last_search_store.dart';
import 'package:on_air/features/search/presentation/search_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

final class OnAirApp extends StatefulWidget {
  const OnAirApp({
    this.connectivityCubit,
    this.signOutCoordinator,
    this.sessionEventSource,
    this.personalDataResetter,
    this.deviceRegistrationService,
    this.uriLinkSource,
    this.linkDomain,
    this.versionGate,
    this.inAppBrowser,
    this.pushMessages,
    super.key,
  });
  final ConnectivityCubit? connectivityCubit;
  final SignOutCoordinator? signOutCoordinator;
  final SessionEventSource? sessionEventSource;
  final PersonalDataResetter? personalDataResetter;
  final DeviceRegistrationService? deviceRegistrationService;
  final UriLinkSource? uriLinkSource;
  final String? linkDomain;

  /// Injectable for tests; production builds resolve it from
  /// `package_info_plus` and the server config.
  final VersionGate? versionGate;

  /// Injectable browser for tests; production resolves it from the backend
  /// mode (mock page or the real in-app browser).
  final InAppBrowser? inAppBrowser;

  /// Injectable push source for tests; production resolves it from the
  /// backend mode (FCM or nothing).
  final PushMessageSource? pushMessages;
  @override
  State<OnAirApp> createState() => _OnAirAppState();
}

final class _OnAirAppState extends State<OnAirApp> {
  late final AuthCubit _authCubit;
  late final ConnectivityCubit _connectivityCubit;
  late final SearchCubit _searchCubit;
  late final AuthRouterRefresh _refresh;
  late final GoRouter _router;
  late final SessionEventSource _sessionEventSource;
  late final PersonalDataResetter _personalDataResetter;
  late final AppLogger _logger;
  late final VersionGate _versionGate;
  late final NotificationSignalSource _signals;
  late final PaymentAttemptCubit _paymentAttemptCubit;
  late final UnreadCountCubit _unreadCountCubit;
  late final PushMessageSource _pushMessages;
  final ValueNotifier<PushMessage?> _banner = ValueNotifier(null);
  Timer? _bannerHideTimer;
  late final AppLifecycleListener _lifecycle;
  late InAppBrowser _browser;
  final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'root',
  );
  StreamSubscription<AuthState>? _authSubscription;
  final List<StreamSubscription<PushMessage>> _pushSubscriptions = [];
  bool _ownsVersionGate = false;
  IncomingLinks? _incomingLinks;

  @override
  void initState() {
    super.initState();
    _logger = context.read<AppLogger>();
    _signals = context.read<NotificationSignalSource>();
    _paymentAttemptCubit = PaymentAttemptCubit(
      flow: context.read<BookingFlowRepository>(),
      store: context.read<PaymentAttemptStore>(),
      browser: () => _browser,
      logger: _logger,
    );
    _unreadCountCubit = UnreadCountCubit(
      notifications: context.read<NotificationsRepository>(),
      signals: _signals,
    );
    _pushMessages = _createPushSource();
    _pushSubscriptions
      ..add(
        _pushMessages.foreground.listen(_showBanner),
      )
      ..add(
        _pushMessages.opened.listen(
          (message) => _router.push(
            NotificationRouter.locationFor(message.type, '', message.targetId),
          ),
        ),
      );
    _browser = widget.inAppBrowser ?? _createBrowser();
    // Resuming the app with an open attempt means the guest came back from
    // the payment page (research R4).
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    _authCubit = AuthCubit(
      context.read<AuthRepository>(),
      currentTermsVersion: '',
      signOutCoordinator: widget.signOutCoordinator,
    );
    _connectivityCubit = widget.connectivityCubit ?? ConnectivityCubit();
    _searchCubit = SearchCubit(
      repo: context.read<ListingsRepository>(),
      lastSearch: context.read<LastSearchStore>(),
      connectivity: _connectivityCubit,
    );
    _sessionEventSource =
        widget.sessionEventSource ?? const NoopSessionEventSource();
    _personalDataResetter =
        widget.personalDataResetter ?? const NoopPersonalDataResetter();
    widget.deviceRegistrationService?.start();
    _ownsVersionGate = widget.versionGate == null;
    _versionGate = widget.versionGate ?? _createVersionGate();
    unawaited(_versionGate.check());
    _refresh = AuthRouterRefresh(_authCubit);
    _router = createAppRouter(
      refreshListenable: Listenable.merge([_refresh, _versionGate]),
      authCubit: _authCubit,
      searchCubit: _searchCubit,
      navigatorKey: _rootNavigatorKey,
      updateRequired: () => _versionGate.updateRequired,
      openStore: _openStore,
    );
    // One live channel per signed-in guest (Guest Plan §12.3): open on the
    // session, close on sign-out and session end.
    _authSubscription = _authCubit.stream.listen(_onAuthStateChanged);
    unawaited(
      _initialize(context.read<AppConfigSource>()),
    );
  }

  void _onAuthStateChanged(AuthState state) => switch (state) {
    SignedIn(:final account) => () {
      unawaited(_signals.start(account.id));
      unawaited(_unreadCountCubit.refresh());
    }(),
    SignedOut() || SessionEnded() => () {
      unawaited(_signals.stop());
      unawaited(_paymentAttemptCubit.newAttempt());
      _unreadCountCubit.reset();
    }(),
    _ => null,
  };

  void _showBanner(PushMessage message) {
    _bannerHideTimer?.cancel();
    _banner.value = message;
    _bannerHideTimer = Timer(const Duration(seconds: 4), () {
      _banner.value = null;
    });
  }

  PushMessageSource _createPushSource() {
    if (widget.pushMessages != null) return widget.pushMessages!;
    // Harnesses that pump the app without a push source (older app tests)
    // simply never receive pushes.
    try {
      return context.read<PushMessageSource>();
    } on ProviderNotFoundException {
      return const NoopPushMessageSource();
    }
  }

  InAppBrowser _createBrowser() {
    // Mock mode pushes the local payment page instead of leaving the app.
    MockBookingServer? mockServer;
    try {
      mockServer = context.read<MockBookingServer?>();
    } on ProviderNotFoundException {
      mockServer = null;
    }
    if (mockServer != null) {
      return MockInAppBrowser(
        navigatorKey: _rootNavigatorKey,
        server: mockServer,
        onReturn: (bookingId) =>
            _router.go(AppRoutes.paymentReturn(bookingId: bookingId)),
      );
    }
    return const UrlLauncherInAppBrowser();
  }

  void _onResume() {
    unawaited(_unreadCountCubit.refresh());
    final state = _paymentAttemptCubit.state;
    if (state is! AttemptOpened) return;
    final path = _router.routerDelegate.currentConfiguration.uri.path;
    if (path == AppRoutes.paymentReturnPath) return;
    _router.go(
      AppRoutes.paymentReturn(bookingId: state.attempt.bookingId),
    );
  }

  VersionGate _createVersionGate() => VersionGate(
    configSource: context.read<AppConfigSource>(),
    installedBuildSource: () async {
      final info = await PackageInfo.fromPlatform();
      return int.tryParse(info.buildNumber);
    },
    platformResolver: () => defaultTargetPlatform,
  );

  Future<void> _openStore() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final url = _storeUrl(defaultTargetPlatform, info);
      if (url == null) return;
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on Object catch (error) {
      _logger.warning('Could not open the store listing: $error');
    }
  }

  Future<void> _initialize(AppConfigSource configRepository) async {
    await _authCubit.restore();
    // The restored session opens the channel too (no state change may fire
    // for a restored sign-in).
    _onAuthStateChanged(_authCubit.state);
    unawaited(_paymentAttemptCubit.restore());
    final source = widget.uriLinkSource;
    final domain = widget.linkDomain;
    if (source != null && domain != null && mounted) {
      _incomingLinks = IncomingLinks(
        source,
        LinkParser(domain),
        _router,
        _authCubit,
      )..start();
    }
    try {
      final config = await configRepository.load();
      _authCubit.updateTermsVersion(config.currentTermsVersion);
    } on Object catch (error) {
      _logger.warning('App config unavailable: $error');
    }
    // A cold-start push opens its screen once the router is ready; the
    // redirect handles sign-in and comes back.
    final initial = await _pushMessages.initial();
    if (initial != null && mounted) {
      unawaited(
        _router.push(
          NotificationRouter.locationFor(initial.type, '', initial.targetId),
        ),
      );
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _bannerHideTimer?.cancel();
    _banner.dispose();
    for (final subscription in _pushSubscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_unreadCountCubit.close());
    unawaited(_authSubscription?.cancel());
    unawaited(_signals.stop());
    unawaited(_incomingLinks?.close());
    unawaited(_paymentAttemptCubit.close());
    _router.dispose();
    _refresh.dispose();
    if (_ownsVersionGate) _versionGate.dispose();
    unawaited(widget.deviceRegistrationService?.close());
    if (_sessionEventSource case final SupabaseSessionEventSource source) {
      unawaited(source.close());
    }
    unawaited(_authCubit.close());
    unawaited(_searchCubit.close());
    if (widget.connectivityCubit == null) {
      unawaited(_connectivityCubit.close());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: _authCubit),
      BlocProvider<ConnectivityCubit>.value(value: _connectivityCubit),
      BlocProvider<PaymentAttemptCubit>.value(value: _paymentAttemptCubit),
      BlocProvider<UnreadCountCubit>.value(value: _unreadCountCubit),
    ],
    child: RepositoryProvider<InAppBrowser>.value(
      value: _browser,
      child: MaterialApp.router(
        routerConfig: _router,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: OnAirTheme.light,
        darkTheme: OnAirTheme.dark,
        // Explicit product choice; keep visible when changing app defaults.
        // ignore: avoid_redundant_argument_values
        themeMode: ThemeMode.system,
        builder: (context, child) => SessionListener(
          router: _router,
          eventSource: _sessionEventSource,
          personalDataResetter: _personalDataResetter,
          deviceRegistrationService: widget.deviceRegistrationService,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Stack(
              children: [
                ?child,
                BlocBuilder<ConnectivityCubit, ConnectivityState>(
                  builder: (context, state) => state.isOnline
                      ? const SizedBox.shrink()
                      : const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: OfflineBanner(),
                        ),
                ),
                ValueListenableBuilder<PushMessage?>(
                  valueListenable: _banner,
                  builder: (context, message, _) => message == null
                      ? const SizedBox.shrink()
                      : Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: InAppNotificationBanner(
                            message: message,
                            onOpen: (opened) {
                              _banner.value = null;
                              unawaited(
                                _router.push(
                                  NotificationRouter.locationFor(
                                    opened.type,
                                    '',
                                    opened.targetId,
                                  ),
                                ),
                              );
                            },
                            onDismiss: () => _banner.value = null,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

String? _storeUrl(
  TargetPlatform platform,
  PackageInfo info,
) => switch (platform) {
  // The Android listing follows the applicationId set in build.gradle.kts.
  TargetPlatform.android =>
    'https://play.google.com/store/apps/details?id=${info.packageName}',
  // TODO(R14): the iOS App Store id is provisional until the listing exists;
  // the store button renders disabled meanwhile.
  TargetPlatform.iOS => null,
  _ => null,
};

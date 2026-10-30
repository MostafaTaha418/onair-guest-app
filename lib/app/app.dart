import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/app_router.dart';
import 'package:on_air/app/router/auth_router_refresh.dart';
import 'package:on_air/app/router/incoming_links.dart';
import 'package:on_air/app/router/link_parser.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/config/version_gate.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/logging/app_logger.dart';
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
import 'package:on_air/features/listings/domain/listings_repository.dart';
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
  StreamSubscription<AuthState>? _authSubscription;
  bool _ownsVersionGate = false;
  IncomingLinks? _incomingLinks;

  @override
  void initState() {
    super.initState();
    _logger = context.read<AppLogger>();
    _signals = context.read<NotificationSignalSource>();
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
    SignedIn(:final account) => unawaited(_signals.start(account.id)),
    SignedOut() || SessionEnded() => unawaited(_signals.stop()),
    _ => null,
  };

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
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    unawaited(_signals.stop());
    unawaited(_incomingLinks?.close());
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
    ],
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
            ],
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

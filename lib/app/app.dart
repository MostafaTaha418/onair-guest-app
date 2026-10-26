import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/app_router.dart';
import 'package:on_air/app/router/auth_router_refresh.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/account_gate/application/device_registration_service.dart';
import 'package:on_air/features/account_gate/application/personal_data_resetter.dart';
import 'package:on_air/features/account_gate/application/sign_out_service.dart';
import 'package:on_air/features/account_gate/presentation/session_listener.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class OnAirApp extends StatefulWidget {
  const OnAirApp({
    this.connectivityCubit,
    this.signOutCoordinator,
    this.sessionEventSource,
    this.personalDataResetter,
    this.deviceRegistrationService,
    super.key,
  });
  final ConnectivityCubit? connectivityCubit;
  final SignOutCoordinator? signOutCoordinator;
  final SessionEventSource? sessionEventSource;
  final PersonalDataResetter? personalDataResetter;
  final DeviceRegistrationService? deviceRegistrationService;
  @override
  State<OnAirApp> createState() => _OnAirAppState();
}

final class _OnAirAppState extends State<OnAirApp> {
  late final AuthCubit _authCubit;
  late final AuthRouterRefresh _refresh;
  late final GoRouter _router;
  late final SessionEventSource _sessionEventSource;
  late final PersonalDataResetter _personalDataResetter;

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit(
      context.read<AuthRepository>(),
      currentTermsVersion: '',
      signOutCoordinator: widget.signOutCoordinator,
    );
    _sessionEventSource =
        widget.sessionEventSource ?? const NoopSessionEventSource();
    _personalDataResetter =
        widget.personalDataResetter ?? const NoopPersonalDataResetter();
    widget.deviceRegistrationService?.start();
    _refresh = AuthRouterRefresh(_authCubit);
    _router = createAppRouter(
      refreshListenable: _refresh,
      authCubit: _authCubit,
    );
    unawaited(
      _initialize(
        context.read<AppConfigSource>(),
        context.read<AppLogger>(),
      ),
    );
  }

  Future<void> _initialize(
    AppConfigSource configRepository,
    AppLogger logger,
  ) async {
    await _authCubit.restore();
    try {
      final config = await configRepository.load();
      _authCubit.updateTermsVersion(config.currentTermsVersion);
    } on Object catch (error) {
      logger.warning('App config unavailable: $error');
    }
  }

  @override
  void dispose() {
    _router.dispose();
    _refresh.dispose();
    unawaited(widget.deviceRegistrationService?.close());
    if (_sessionEventSource case final SupabaseSessionEventSource source) {
      unawaited(source.close());
    }
    unawaited(_authCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: _authCubit),
      if (widget.connectivityCubit case final cubit?)
        BlocProvider<ConnectivityCubit>.value(value: cubit)
      else
        BlocProvider<ConnectivityCubit>(create: (_) => ConnectivityCubit()),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

extension PumpOnAirApp on WidgetTester {
  Future<void> pumpOnAirApp(
    Widget child, {
    required AuthRepository authRepository,
    required AppConfigSource appConfigRepository,
    AuthCubit? authCubit,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final cubit =
        authCubit ??
        AuthCubit(
          authRepository,
          currentTermsVersion:
              (await appConfigRepository.load()).currentTermsVersion,
        );
    await pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: authRepository),
          RepositoryProvider<AppConfigSource>.value(value: appConfigRepository),
        ],
        child: BlocProvider<AuthCubit>.value(
          value: cubit,
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: OnAirTheme.light,
            darkTheme: OnAirTheme.dark,
            themeMode: themeMode,
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: child,
            ),
          ),
        ),
      ),
    );
    addTearDown(cubit.close);
  }
}

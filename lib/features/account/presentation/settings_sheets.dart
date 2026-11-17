import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/app/settings/app_settings_cubit.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The language and appearance radio sheets (contracts/ui-screens.md
/// §Account): radio rows applying immediately through [AppSettingsCubit].
/// English is hidden when the config flag hides it (§19.6).

Future<void> showLanguageSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.vertical(
          top: Radius.circular(Dimens.radiusSheet),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<AppSettingsCubit>(),
        child: const _LanguageSheet(),
      ),
    );

Future<void> showAppearanceSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.vertical(
          top: Radius.circular(Dimens.radiusSheet),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<AppSettingsCubit>(),
        child: const _AppearanceSheet(),
      ),
    );

final class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.watch<AppSettingsCubit>();
    final settings = cubit.state;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          Dimens.screenSide,
          Dimens.space8,
          Dimens.screenSide,
          Dimens.space16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.accountLanguage,
              style: context.textStyles.sectionTitle,
            ),
            const SizedBox(height: Dimens.space8),
            _radio(
              context: context,
              label: l10n.settingsLanguageArabic,
              selected: settings.locale.languageCode == 'ar',
              onTap: () {
                cubit.setLocale(const Locale('ar')).ignore();
                Navigator.of(context).pop();
              },
            ),
            // §19.6: the config flag can hide English entirely.
            if (settings.englishEnabled)
              _radio(
                context: context,
                label: l10n.settingsLanguageEnglish,
                selected: settings.locale.languageCode == 'en',
                onTap: () {
                  cubit.setLocale(const Locale('en')).ignore();
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

final class _AppearanceSheet extends StatelessWidget {
  const _AppearanceSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.watch<AppSettingsCubit>();
    final settings = cubit.state;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          Dimens.screenSide,
          Dimens.space8,
          Dimens.screenSide,
          Dimens.space16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.accountAppearance,
              style: context.textStyles.sectionTitle,
            ),
            const SizedBox(height: Dimens.space8),
            _radio(
              context: context,
              label: l10n.settingsThemeSystem,
              selected: settings.themeMode == ThemeMode.system,
              onTap: () {
                cubit.setThemeMode(ThemeMode.system).ignore();
                Navigator.of(context).pop();
              },
            ),
            _radio(
              context: context,
              label: l10n.settingsThemeLight,
              selected: settings.themeMode == ThemeMode.light,
              onTap: () {
                cubit.setThemeMode(ThemeMode.light).ignore();
                Navigator.of(context).pop();
              },
            ),
            _radio(
              context: context,
              label: l10n.settingsThemeDark,
              selected: settings.themeMode == ThemeMode.dark,
              onTap: () {
                cubit.setThemeMode(ThemeMode.dark).ignore();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _radio({
  required BuildContext context,
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  final colors = context.colors;
  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      selected ? Icons.radio_button_checked : Icons.radio_button_off,
      color: selected ? colors.primary : colors['textMuted'],
    ),
    title: Text(label),
    onTap: onTap,
  );
}

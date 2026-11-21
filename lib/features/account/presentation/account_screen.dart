import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/app/settings/app_settings_cubit.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/payments/in_app_browser.dart';
import 'package:on_air/design_system/components/on_air_confirm_sheet.dart';
import 'package:on_air/design_system/components/settings_row.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/design_system/typography/on_air_text_styles.dart';
import 'package:on_air/features/account/presentation/edit_name_sheet.dart';
import 'package:on_air/features/account/presentation/settings_sheets.dart';
import 'package:on_air/features/account/presentation/widgets/account_info_row.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/egypt_phone.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/auth/presentation/widgets/rapid_submit_guard.dart';
import 'package:on_air/features/support/domain/support_repository.dart';
import 'package:on_air/features/support/presentation/widgets/call_support_button.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// «حسابي» (US5, contracts/ui-screens.md §Account): the #12 header, the
/// S005 profile rows, the settings groups, legal links, and the danger
/// zone — plus the visitor variant (FR-028).
final class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // No app bar: the screen opens straight on the profile photo and name.
    // SafeArea keeps that content below the status bar; the bottom is handled
    // app-wide and by the list's navBarClearance padding.
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is SignedIn) {
              return _SignedInAccount(account: state.account);
            }
            if (state is SigningOut) return const LoadingView();
            return const _VisitorAccount();
          },
        ),
      ),
    );
  }
}

final class _SignedInAccount extends StatelessWidget {
  const _SignedInAccount({required this.account});

  final GuestAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final providers = account.authProviders
        .map(
          (provider) => switch (provider) {
            AuthProvider.google => l10n.accountMethodGoogle,
            AuthProvider.apple => l10n.accountMethodApple,
            AuthProvider.email => l10n.accountMethodEmail,
          },
        )
        .toList();
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        Dimens.screenSide,
        Dimens.screenSide,
        Dimens.screenSide,
        Dimens.navBarClearance,
      ),
      children: [
        _AccountHeader(account: account),
        const SizedBox(height: Dimens.space16),
        _profileCard(context, l10n, providers),
        const SizedBox(height: Dimens.space16),
        SettingsGroup(
          label: l10n.accountSectionGeneral,
          children: [
            SettingsRow(
              key: const ValueKey('account-notifications-row'),
              icon: Icons.notifications_outlined,
              title: l10n.accountNotifications,
              showChevron: true,
              onTap: () => context.push(AppRoutes.accountNotifications),
            ),
            SettingsRow(
              key: const ValueKey('account-appearance-row'),
              icon: Icons.dark_mode_outlined,
              tone: SettingsIconTone.teal,
              title: l10n.accountAppearance,
              value: _appearanceLabel(context),
              showChevron: true,
              onTap: () => showAppearanceSheet(context),
            ),
            SettingsRow(
              key: const ValueKey('account-language-row'),
              icon: Icons.language_outlined,
              tone: SettingsIconTone.orange,
              title: l10n.accountLanguage,
              value: _languageLabel(context),
              showChevron: true,
              onTap: () => showLanguageSheet(context),
            ),
          ],
        ),
        const SizedBox(height: Dimens.space16),
        SettingsGroup(
          label: l10n.accountSectionSecurity,
          children: [
            SettingsRow(
              key: const ValueKey('account-security-row'),
              icon: Icons.shield_outlined,
              tone: SettingsIconTone.neutral,
              title: l10n.accountSecurityRow,
              showChevron: true,
              onTap: () => context.push(AppRoutes.accountSecurity),
            ),
          ],
        ),
        const SizedBox(height: Dimens.space16),
        const _SupportSettingsGroup(),
        const SizedBox(height: Dimens.space16),
        SettingsGroup(
          label: l10n.accountSectionLegal,
          children: [
            SettingsRow(
              key: const ValueKey('account-terms-row'),
              icon: Icons.description_outlined,
              tone: SettingsIconTone.neutral,
              title: l10n.accountTerms,
              showChevron: true,
              onTap: () => _openLegal(context, terms: true),
            ),
            SettingsRow(
              key: const ValueKey('account-privacy-row'),
              icon: Icons.privacy_tip_outlined,
              tone: SettingsIconTone.neutral,
              title: l10n.accountPrivacy,
              showChevron: true,
              onTap: () => _openLegal(context, terms: false),
            ),
          ],
        ),
        const SizedBox(height: Dimens.space16),
        SettingsGroup(
          children: [
            const _SignOutRow(),
            SettingsRow(
              key: const ValueKey('account-delete-row'),
              icon: Icons.delete_forever_outlined,
              tone: SettingsIconTone.danger,
              title: l10n.deleteTitle,
              showChevron: true,
              onTap: () => context.push(AppRoutes.accountDelete),
            ),
          ],
        ),
        const SizedBox(height: Dimens.space24),
      ],
    );
  }

  Widget _profileCard(
    BuildContext context,
    AppLocalizations l10n,
    List<String> providers,
  ) {
    final colors = context.colors;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(Dimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AccountInfoRow(
              key: const ValueKey('account-method-row'),
              icon: AppIcons.keyOutline,
              label: l10n.accountSignInMethod,
              value: providers.join(l10n.listSeparator),
            ),
            if (account.phone != null) ...[
              const SizedBox(height: Dimens.space12),
              AccountInfoRow(
                key: const ValueKey('account-phone-row'),
                icon: AppIcons.phoneOutlined,
                label: l10n.accountPhone,
                value: maskPhone(account.phone!),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (account.phoneVerified)
                      StatusChip(
                        key: const ValueKey('account-phone-chip'),
                        label: l10n.accountPhoneConfirmed,
                        tone: StatusTone.success,
                      ),
                    TextButton(
                      key: const ValueKey('account-change-phone'),
                      onPressed: () => context.push(AppRoutes.accountPhone),
                      style: TextButton.styleFrom(
                        foregroundColor: colors['textAccent'],
                      ),
                      child: Text(l10n.accountChangePhone),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _appearanceLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mode = context.watch<AppSettingsCubit>().state.themeMode;
    return switch (mode) {
      ThemeMode.system => l10n.settingsThemeSystem,
      ThemeMode.light => l10n.settingsThemeLight,
      ThemeMode.dark => l10n.settingsThemeDark,
    };
  }

  String _languageLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final code = context.watch<AppSettingsCubit>().state.locale.languageCode;
    return code == 'en'
        ? l10n.settingsLanguageEnglish
        : l10n.settingsLanguageArabic;
  }

  Future<void> _openLegal(BuildContext context, {required bool terms}) async {
    final l10n = AppLocalizations.of(context);
    final browser = context.read<InAppBrowser>();
    final config = await context.read<AppConfigSource>().load();
    final locale = l10n.localeName;
    final url = terms
        ? config.legal.termsUrl(locale)
        : config.legal.privacyUrl(locale);
    if (url == null || !context.mounted) return;
    await browser.open(url, bookingId: '');
  }
}

final class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.account});

  final GuestAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final online = context.select<ConnectivityCubit, bool>(
      (cubit) => cubit.state.isOnline,
    );
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.primary, width: 2),
          ),
          child: Text(
            account.initials,
            style: Theme.of(context).textTheme.titleLarge?.onAirExtraBold
                .copyWith(
                  color: colors.primary,
                ),
          ),
        ),
        const SizedBox(width: Dimens.space16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.fullName ?? l10n.accountNameLabel,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.onAirExtraBold,
              ),
              if (account.email != null)
                Text(
                  account.email!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        TextButton(
          key: const ValueKey('account-edit-name'),
          onPressed: online
              ? () => showEditNameSheet(
                  context,
                  currentName: account.fullName ?? '',
                )
              : null,
          child: Text(l10n.accountEdit),
        ),
      ],
    );
  }
}

/// The support group is built after config arrives so a missing phone removes
/// the call row and its divider completely (US3-4 / T073).
final class _SupportSettingsGroup extends StatelessWidget {
  const _SupportSettingsGroup();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder(
      future: context.read<AppConfigSource>().load().then(
        (config) => config.supportContact.phone,
      ),
      builder: (context, snapshot) {
        final phone = snapshot.data;
        return SettingsGroup(
          label: l10n.accountSectionSupport,
          children: [
            SettingsRow(
              key: const ValueKey('account-support-row'),
              icon: Icons.support_agent_outlined,
              title: l10n.supportTitle,
              showChevron: true,
              trailing: const _SupportUnreadDot(),
              onTap: () => context.push(AppRoutes.support),
            ),
            SettingsRow(
              key: const ValueKey('account-faq-row'),
              icon: Icons.quiz_outlined,
              tone: SettingsIconTone.teal,
              title: l10n.supportFaq,
              showChevron: true,
              onTap: () => context.push(AppRoutes.supportFaq),
            ),
            if (phone != null && phone.isNotEmpty)
              SettingsRow(
                key: const ValueKey('account-call-row'),
                icon: Icons.call_outlined,
                title: l10n.supportCall,
                showChevron: true,
                onTap: () => launchSupportDial(context, phone),
              ),
          ],
        );
      },
    );
  }
}

final class _SignOutRow extends StatefulWidget {
  const _SignOutRow();

  @override
  State<_SignOutRow> createState() => _SignOutRowState();
}

final class _SignOutRowState extends State<_SignOutRow> {
  final _guard = RapidSubmitGuard();
  bool _busy = false;

  Future<void> _confirm() async {
    if (_busy || !_guard.tryEnter()) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final authCubit = context.read<AuthCubit>();
    final accepted = await OnAirConfirmSheet.show<bool>(
      context,
      builder: (sheetContext) => OnAirConfirmSheet(
        title: l10n.accountSignOutConfirm,
        body: '',
        confirmLabel: l10n.accountSignOut,
        cancelLabel: l10n.supportKeepEditing,
        onConfirm: () => Navigator.of(sheetContext).pop(true),
      ),
    );
    if (accepted ?? false) {
      await authCubit.signOut();
      if (mounted) context.go(AppRoutes.home);
      return;
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => SettingsRow(
    key: const ValueKey('account-sign-out-row'),
    icon: Icons.logout_outlined,
    tone: SettingsIconTone.danger,
    title: AppLocalizations.of(context).accountSignOut,
    showChevron: true,
    enabled: !_busy,
    onTap: _confirm,
  );
}

/// The support row's unread dot follows the repository flag (T073): one
/// first-page read decides whether any case has a staff reply waiting.
final class _SupportUnreadDot extends StatelessWidget {
  const _SupportUnreadDot();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: context.read<SupportRepository>().anyUnreadStaffReply(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return Container(
          key: const ValueKey('support-unread-dot'),
          width: 8,
          height: 8,
          margin: const EdgeInsetsDirectional.only(end: Dimens.space8),
          decoration: BoxDecoration(
            color: context.colors.primary,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

final class _VisitorAccount extends StatelessWidget {
  const _VisitorAccount();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        Dimens.screenSide,
        Dimens.screenSide,
        Dimens.screenSide,
        Dimens.navBarClearance,
      ),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(Dimens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.accountVisitorTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.onAirExtraBold,
                ),
                const SizedBox(height: Dimens.space16),
                FilledButton(
                  key: const ValueKey('visitor-sign-in'),
                  onPressed: () => context.push(AppRoutes.login),
                  child: Text(l10n.signIn),
                ),
                const SizedBox(height: Dimens.space8),
                OutlinedButton(
                  key: const ValueKey('visitor-register'),
                  onPressed: () => context.push(AppRoutes.register),
                  child: Text(l10n.authCreateAccount),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Dimens.space16),
        SettingsGroup(
          label: l10n.accountSectionGeneral,
          children: [
            SettingsRow(
              key: const ValueKey('account-appearance-row'),
              icon: Icons.dark_mode_outlined,
              tone: SettingsIconTone.teal,
              title: l10n.accountAppearance,
              showChevron: true,
              onTap: () => showAppearanceSheet(context),
            ),
            SettingsRow(
              key: const ValueKey('account-language-row'),
              icon: Icons.language_outlined,
              tone: SettingsIconTone.orange,
              title: l10n.accountLanguage,
              showChevron: true,
              onTap: () => showLanguageSheet(context),
            ),
          ],
        ),
        const SizedBox(height: Dimens.space16),
        SettingsGroup(
          label: l10n.accountSectionSupport,
          children: [
            SettingsRow(
              key: const ValueKey('account-faq-row'),
              icon: Icons.quiz_outlined,
              tone: SettingsIconTone.teal,
              title: l10n.supportFaq,
              showChevron: true,
              onTap: () => context.push(AppRoutes.supportFaq),
            ),
          ],
        ),
        const SizedBox(height: Dimens.space16),
        SettingsGroup(
          label: l10n.accountSectionLegal,
          children: [
            SettingsRow(
              key: const ValueKey('account-terms-row'),
              icon: Icons.description_outlined,
              tone: SettingsIconTone.neutral,
              title: l10n.accountTerms,
              showChevron: true,
              onTap: () => _openLegal(context, terms: true),
            ),
            SettingsRow(
              key: const ValueKey('account-privacy-row'),
              icon: Icons.privacy_tip_outlined,
              tone: SettingsIconTone.neutral,
              title: l10n.accountPrivacy,
              showChevron: true,
              onTap: () => _openLegal(context, terms: false),
            ),
          ],
        ),
        const SizedBox(height: Dimens.space16),
        const CallSupportButton(),
        const SizedBox(height: Dimens.space24),
      ],
    );
  }

  Future<void> _openLegal(BuildContext context, {required bool terms}) async {
    final l10n = AppLocalizations.of(context);
    final config = await context.read<AppConfigSource>().load();
    final locale = l10n.localeName;
    final url = terms
        ? config.legal.termsUrl(locale)
        : config.legal.privacyUrl(locale);
    if (url == null || !context.mounted) return;
    await context.read<InAppBrowser>().open(url, bookingId: '');
  }
}

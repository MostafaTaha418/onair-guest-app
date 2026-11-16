import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// The dialer call, injectable so tests never touch the platform channel.
typedef UrlCanLaunch = Future<bool> Function(Uri uri);
typedef UrlLaunch = Future<bool> Function(Uri uri);

Future<bool> _defaultCanLaunch(Uri uri) => canLaunchUrl(uri);

Future<bool> _defaultLaunch(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// «اتصل بخدمة العملاء» + the working hours, reading
/// `AppConfig.supportContact` (task T061). Without a published number the
/// button hides rather than breaking (US3-4); without a dialer the number
/// opens in a sheet with a copy action (US3-5).
final class CallSupportButton extends StatefulWidget {
  const CallSupportButton({
    this.canLaunch = _defaultCanLaunch,
    this.launch = _defaultLaunch,
    super.key,
  });

  final UrlCanLaunch canLaunch;
  final UrlLaunch launch;

  @override
  State<CallSupportButton> createState() => _CallSupportButtonState();
}

final class _CallSupportButtonState extends State<CallSupportButton> {
  SupportContact? _contact;

  @override
  void initState() {
    super.initState();
    unawaited(_loadConfig());
  }

  /// The config is public and cached by its own repository; a failure just
  /// keeps the button hidden (US3-4).
  Future<void> _loadConfig() async {
    try {
      final config = await context.read<AppConfigSource>().load();
      if (!mounted) return;
      setState(() => _contact = config.supportContact);
    } on Object {
      // Hidden: there is no published number to call.
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      if (await widget.canLaunch(uri)) {
        await widget.launch(uri);
        return;
      }
    } on Object {
      // Fall through to the copy sheet.
    }
    if (mounted) await _showNumberSheet(phone);
  }

  Future<void> _showNumberSheet(String phone) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(Dimens.space16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: SelectableText(
                  phone,
                  style: Theme.of(sheetContext).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: Dimens.space16),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: phone));
                  if (!sheetContext.mounted) return;
                  Navigator.of(sheetContext).pop();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text(l10n.supportCallCopied)),
                    );
                },
                icon: const Icon(Icons.copy_rounded),
                label: Text(l10n.supportCallCopied),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contact = _contact;
    final phone = contact?.phone;
    if (phone == null || phone.isEmpty) return const SizedBox.shrink();
    final hours = contact!.hours(l10n.localeName);
    return Card(
      margin: EdgeInsets.zero,
      child: Semantics(
        button: true,
        label: l10n.supportCall,
        child: InkWell(
          borderRadius: BorderRadius.circular(Dimens.radiusCard),
          onTap: () => _call(phone),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(Dimens.space16),
            child: Row(
              children: [
                const Icon(Icons.support_agent),
                const SizedBox(width: Dimens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.supportCall,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (hours != null)
                        Text(
                          l10n.supportCallHours(hours),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  textDirection: Directionality.of(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

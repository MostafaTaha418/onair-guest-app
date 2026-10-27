import 'package:flutter/material.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class NotAvailableScreen extends StatelessWidget {
  const NotAvailableScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: EmptyView(
      icon: Icons.info_outline,
      message: AppLocalizations.of(context).notAvailable,
    ),
  );
}

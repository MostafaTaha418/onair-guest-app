import 'package:flutter/material.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class BookingsPlaceholderScreen extends StatelessWidget {
  const BookingsPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: EmptyView(
      icon: Icons.calendar_month_outlined,
      message: AppLocalizations.of(context).bookingsEmpty,
    ),
  );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/design_system/components/amount_row.dart';
import 'package:on_air/design_system/components/bottom_action_bar.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/bookings/domain/booking_parts.dart';
import 'package:on_air/features/stay/presentation/cash/cash_receipt_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class CashReceiptScreen extends StatelessWidget {
  const CashReceiptScreen({
    required this.bookingId,
    required this.paymentId,
    super.key,
  });

  final String bookingId;
  final String paymentId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<CashReceiptCubit, CashReceiptState>(
      listener: (context, state) {
        if (state is ReceiptMissing) {
          context.go(AppRoutes.bookingDetails(bookingId));
        }
      },
      builder: (context, state) {
        final ready = state is ReceiptReady ? state : null;
        return Scaffold(
          // The success title lives in the body header (contracts
          // ui-screens.md §5), so the bar stays titleless.
          appBar: AppBar(),
          bottomNavigationBar: ready == null
              ? null
              : BottomActionBar(
                  leading: const SizedBox.shrink(),
                  action: OnAirPrimaryButton(
                    label: l10n.receiptBack,
                    onPressed: () =>
                        context.go(AppRoutes.bookingDetails(bookingId)),
                  ),
                ),
          body: ready == null
              ? const SizedBox.shrink()
              : _ReceiptBody(line: ready.line),
        );
      },
    );
  }
}

final class _ReceiptBody extends StatelessWidget {
  const _ReceiptBody({required this.line});

  final PaymentLine line;

  void _copyReceiptNumber(BuildContext context, AppLocalizations l10n) {
    final receipt = line.receipt!;
    unawaited(Clipboard.setData(ClipboardData(text: receipt.receiptNo)));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.receiptCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final receipt = line.receipt!;
    return ListView(
      padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Dimens.space16),
                Icon(
                  AppIcons.checkCircle,
                  size: 64,
                  color: context.colors['success'],
                ),
                const SizedBox(height: Dimens.space16),
                Text(
                  l10n.receiptTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: Dimens.space16),
                Card(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(Dimens.space16),
                    child: Column(
                      children: [
                        AmountRow(
                          label: l10n.cashAmountLabel,
                          value: MoneyFormatter().format(line.amount),
                        ),
                        AmountRow(
                          label: l10n.cashCollectorLabel,
                          value: receipt.collectorDisplayName,
                        ),
                        AmountRow(
                          label: l10n.receiptDate,
                          value: formatCairoDayMonthTime(
                            receipt.confirmedAt,
                            locale: AppLocalizations.of(context).localeName,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: AmountRow(
                                label: l10n.receiptNumber,
                                value: receipt.receiptNo,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(AppIcons.copy),
                              tooltip: l10n.bookingCopyCode,
                              onPressed: () =>
                                  _copyReceiptNumber(context, l10n),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/features/stay/domain/cancellation_preview.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The sentence explaining the server's cancellation case (contracts
/// ui-screens.md §7). Every amount is shown as received — nothing is
/// computed here.
String cancellationSentence(CancellationPreview p, AppLocalizations l10n) {
  final fmt = MoneyFormatter().format;
  return switch (p.policyCase) {
    PolicyCase.free => l10n.cancelReasonFree(fmt(p.refund)),
    PolicyCase.depositLost =>
      p.freeCancellationUntil == null
          ? l10n.cancelReasonDepositLostNoDate(
              fmt(p.refund),
              fmt(p.nonRefundable),
            )
          : l10n.cancelReasonDepositLost(
              fmt(p.refund),
              fmt(p.nonRefundable),
              formatCairoDayMonthTime(
                p.freeCancellationUntil!,
                locale: l10n.localeName,
              ),
            ),
    PolicyCase.noRefund => l10n.cancelReasonNoRefund,
    PolicyCase.unknown => l10n.bookingMsgUnknown,
  };
}

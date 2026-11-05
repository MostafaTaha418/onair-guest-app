import 'package:on_air/core/money/money.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/features/bookings/domain/booking_stay_parts.dart';
import 'package:on_air/features/stay/domain/damage_claim.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

String claimStatusLabel(DamageClaimStatus status, AppLocalizations l10n) =>
    switch (status) {
      DamageClaimStatus.open => l10n.claimStatusOpen,
      DamageClaimStatus.guestAccepted => l10n.claimStatusAccepted,
      DamageClaimStatus.guestDisputed => l10n.claimStatusDisputed,
      DamageClaimStatus.inMediation => l10n.claimStatusMediation,
      DamageClaimStatus.resolved => l10n.claimStatusResolved,
      DamageClaimStatus.withdrawn => l10n.claimStatusWithdrawn,
      DamageClaimStatus.unknown => l10n.claimStatusUnknown,
    };

StatusTone claimStatusTone(DamageClaimStatus status) => switch (status) {
  DamageClaimStatus.open => StatusTone.warning,
  DamageClaimStatus.guestAccepted ||
  DamageClaimStatus.resolved => StatusTone.completed,
  DamageClaimStatus.guestDisputed ||
  DamageClaimStatus.inMediation => StatusTone.pending,
  DamageClaimStatus.withdrawn ||
  DamageClaimStatus.unknown => StatusTone.cancelled,
};

String claimOutcomeText(ClaimResolution resolution, AppLocalizations l10n) {
  final fmt = MoneyFormatter().format;
  return switch (resolution.outcome) {
    ClaimOutcome.guestPays => l10n.claimOutcomeGuestPays(
      fmt(resolution.amount!),
    ),
    ClaimOutcome.partial => l10n.claimOutcomePartial(fmt(resolution.amount!)),
    ClaimOutcome.noCharge => l10n.claimOutcomeNoCharge,
    ClaimOutcome.withdrawn => l10n.claimOutcomeWithdrawn,
    ClaimOutcome.unknown => l10n.bookingMsgUnknown,
  };
}

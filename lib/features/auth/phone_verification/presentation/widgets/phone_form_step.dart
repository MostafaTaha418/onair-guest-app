import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/on_air_text_field.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/phone_verification/presentation/phone_verification_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The «أكّد رقمك» form fields (contracts/ui-screens.md §4.1): the name is
/// shown only when the account misses one, the terms only when none are
/// accepted. «متابعة» stays disabled until the form is valid and shows the
/// loader inside the button while submitting.
final class PhoneFormStep extends StatefulWidget {
  const PhoneFormStep({
    required this.needsName,
    required this.needsTerms,
    super.key,
  });

  final bool needsName;
  final bool needsTerms;

  @override
  State<PhoneFormStep> createState() => _PhoneFormStepState();
}

class _PhoneFormStepState extends State<PhoneFormStep> {
  final _phoneController = TextEditingController();
  late final _nameController = TextEditingController(
    text: context.read<PhoneVerificationCubit>().prefilledName ?? '',
  );

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? _errorText(String? key, AppLocalizations l10n) => switch (key) {
    'authFieldRequired' => l10n.authFieldRequired,
    'authPhoneInvalid' => l10n.authPhoneInvalid,
    'authNameInvalid' => l10n.authNameInvalid,
    'authPhoneAlreadyUsed' => l10n.authPhoneAlreadyUsed,
    'authPhoneCountryNotSupported' => l10n.authPhoneCountryNotSupported,
    _ => null,
  };

  String? _generalErrorText(
    String? key,
    AppLocalizations l10n,
    String? requestId,
  ) => key == null ? null : localizedErrorText(key, l10n, requestId: requestId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<PhoneVerificationCubit, PvState>(
      builder: (context, state) {
        // Blocked on the form step: the same form from its snapshot with
        // «متابعة» disabled behind the BlockedNotice (T064).
        final (form, blocked) = switch (state) {
          PvForm() => (state, false),
          PvBlocked(:final form) when form != null => (form, true),
          _ => (const PvForm(), false),
        };
        final cubit = context.read<PhoneVerificationCubit>();
        // Keep the controllers in sync without stealing the caret.
        if (_phoneController.text != form.phoneText) {
          _phoneController.text = form.phoneText;
        }
        if (_nameController.text != form.nameText) {
          _nameController.text = form.nameText;
        }
        final valid = cubit.isFormValid && !form.submitting;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.needsName) ...[
              OnAirTextField(
                key: const ValueKey('confirm-phone-name-field'),
                controller: _nameController,
                label: l10n.fullName,
                prefixIcon: AppIcons.personOutlineRounded,
                pill: true,
                enabled: !form.submitting,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                errorText: _errorText(form.nameErrorKey, l10n),
                onChanged: cubit.onNameChanged,
              ),
              const SizedBox(height: Dimens.space20),
            ],
            OnAirTextField(
              key: const ValueKey('confirm-phone-field'),
              controller: _phoneController,
              label: l10n.phoneNumber,
              prefixIcon: AppIcons.phoneOutlined,
              pill: true,
              keyboardType: TextInputType.phone,
              enabled: !form.submitting,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumber],
              errorText: _errorText(form.phoneErrorKey, l10n),
              onChanged: cubit.onPhoneChanged,
            ),
            if (widget.needsTerms) ...[
              CheckboxListTile(
                key: const ValueKey('confirm-phone-terms'),
                contentPadding: EdgeInsets.zero,
                value: form.termsAccepted,
                onChanged: form.submitting
                    ? null
                    : (value) => cubit.onTermsChanged(accepted: value ?? false),
                title: Text(l10n.authAcceptTerms),
                subtitle: form.termsChanged
                    ? Text(
                        l10n.authTermsChanged,
                        key: const ValueKey('confirm-phone-terms-changed'),
                      )
                    : null,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
            if (_generalErrorText(
                  form.generalErrorKey,
                  l10n,
                  form.generalErrorRequestId,
                ) !=
                null) ...[
              const SizedBox(height: Dimens.space12),
              Semantics(
                liveRegion: true,
                child: Text(
                  _generalErrorText(
                    form.generalErrorKey,
                    l10n,
                    form.generalErrorRequestId,
                  )!,
                  key: const ValueKey('confirm-phone-general-error'),
                  style: TextStyle(color: context.colors.errorText),
                ),
              ),
            ],
            const SizedBox(height: Dimens.space24),
            Center(
              child: SizedBox(
                width: 230,
                child: OnAirPrimaryButton(
                  key: const ValueKey('confirm-phone-continue'),
                  label: l10n.confirmPhoneContinue,
                  onPressed: valid && !blocked ? cubit.submit : null,
                  isLoading: form.submitting,
                  gradient: true,
                  pill: true,
                  height: 62,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

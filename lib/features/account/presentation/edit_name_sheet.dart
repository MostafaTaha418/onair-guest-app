import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/on_air_text_field.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/auth/presentation/widgets/rapid_submit_guard.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// «تعديل الاسم» (contracts/ui-screens.md §Account): one field with live
/// 2–80 validation, «حفظ» with a loader, keyboard-safe.
Future<void> showEditNameSheet(
  BuildContext context, {
  required String currentName,
}) => OnAirEditNameSheet.show(context, currentName: currentName);

final class OnAirEditNameSheet extends StatefulWidget {
  const OnAirEditNameSheet({required this.currentName, super.key});

  final String currentName;

  static Future<void> show(
    BuildContext context, {
    required String currentName,
  }) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadiusDirectional.vertical(
        top: Radius.circular(Dimens.radiusSheet),
      ),
    ),
    backgroundColor: context.colors.surface,
    builder: (_) => OnAirEditNameSheet(currentName: currentName),
  );

  @override
  State<OnAirEditNameSheet> createState() => _OnAirEditNameSheetState();
}

final class _OnAirEditNameSheetState extends State<OnAirEditNameSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentName,
  );
  final _guard = RapidSubmitGuard();
  bool _saving = false;
  ApiError? _error;

  bool get _valid {
    final value = _controller.text.trim();
    return value.length >= 2 && value.length <= 80;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_valid || _saving || !_guard.tryEnter()) return;
    setState(() => _saving = true);
    final repository = context.read<AccountRepository>();
    final authCubit = context.read<AuthCubit>();
    try {
      await repository.updateProfile(fullName: _controller.text.trim());
      // The header re-renders from AuthCubit once the profile is re-read
      // (S005 refreshAccount).
      await authCubit.refreshAccount();
      if (!mounted) return;
      Navigator.of(context).pop();
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = failure.error;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = const ApiError(
          code: ErrorCode.internal,
          messageKey: 'errorUnexpected',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding:
          EdgeInsetsDirectional.only(
            bottom: insets,
          ).add(
            const EdgeInsetsDirectional.fromSTEB(
              Dimens.screenSide,
              Dimens.space8,
              Dimens.screenSide,
              Dimens.space16,
            ),
          ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.accountEditName,
              style: context.textStyles.sectionTitle,
            ),
            const SizedBox(height: Dimens.space16),
            OnAirTextField(
              key: const ValueKey('edit-name-field'),
              controller: _controller,
              label: l10n.accountNameLabel,
              maxLength: 80,
              errorText: !_valid
                  ? l10n.accountNameInvalid
                  : _error == null
                  ? null
                  : apiErrorMessage(_error!, l10n),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: Dimens.space16),
            OnAirPrimaryButton(
              key: const ValueKey('edit-name-save'),
              label: l10n.accountSave,
              isLoading: _saving,
              onPressed: _valid && !_saving ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}

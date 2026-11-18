import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/files/attachment_picker.dart';
import 'package:on_air/core/files/image_sanitizer.dart';
import 'package:on_air/core/files/private_file_uploader.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/design_system/components/bottom_action_bar.dart';
import 'package:on_air/design_system/components/on_air_confirm_sheet.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/on_air_text_field.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/presentation/widgets/rapid_submit_guard.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/features/support/presentation/new_case/new_case_cubit.dart';
import 'package:on_air/features/support/presentation/support_texts.dart';
import 'package:on_air/features/support/presentation/widgets/attachment_strip.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// «حالة جديدة» (US2): a required type, an optional booking/apartment link,
/// a description of 10–4000 characters, up to 5 attachments, sent exactly
/// once per draft.
final class NewCaseScreen extends StatefulWidget {
  const NewCaseScreen({super.key});

  @override
  State<NewCaseScreen> createState() => _NewCaseScreenState();
}

final class _NewCaseScreenState extends State<NewCaseScreen> {
  final _guard = RapidSubmitGuard();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_guard.tryEnter()) {
      unawaited(context.read<NewCaseCubit>().submit());
    }
  }

  Future<void> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    final discard = await OnAirConfirmSheet.show<bool>(
      context,
      builder: (sheetContext) => OnAirConfirmSheet(
        title: l10n.supportDiscardTitle,
        body: '',
        confirmLabel: l10n.supportDiscard,
        cancelLabel: l10n.supportKeepEditing,
        onConfirm: () => Navigator.of(sheetContext).pop(true),
      ),
    );
    if ((discard ?? false) && mounted) Navigator.of(context).pop();
  }

  Future<void> _pickBooking() async {
    final repository = context.read<BookingsRepository>();
    final cubit = context.read<NewCaseCubit>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _BookingLinkSheet(
        repository: repository,
        onSelected: cubit.linkBooking,
      ),
    );
  }

  void _onStateChanged(BuildContext context, NewCaseState state) {
    final l10n = AppLocalizations.of(context);
    if (state is NewCaseCreated) {
      final messenger = ScaffoldMessenger.of(context);
      context.pushReplacement(AppRoutes.supportCase(state.caseId));
      // A snackbar shown before the replacement dies with the replaced
      // scaffold; present it once the destination scaffold has mounted.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.supportCreated(state.code))),
        );
      });
    } else if (state is NewCaseReady && state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(state.error!, l10n))),
      );
      context.read<NewCaseCubit>().acknowledgeError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final current = context.read<NewCaseCubit>().state;
        if (current is NewCaseReady && current.hasContent) {
          unawaited(_confirmDiscard());
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        // canPop is false while there is content, so the framework would
        // omit the back control; an explicit BackButton always shows, and
        // its maybePop runs the discard check through the PopScope above.
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(l10n.supportNewCase),
        ),
        body: BlocConsumer<NewCaseCubit, NewCaseState>(
          listener: _onStateChanged,
          builder: (context, state) {
            if (state is! NewCaseReady) return const SizedBox.shrink();
            return Column(
              children: [
                if (!state.online) const OfflineBanner(),
                Expanded(child: _form(context, state)),
              ],
            );
          },
        ),
        bottomNavigationBar: BlocBuilder<NewCaseCubit, NewCaseState>(
          builder: (context, state) {
            if (state is! NewCaseReady) return const SizedBox.shrink();
            return BottomActionBar(
              leading: const SizedBox.shrink(),
              action: OnAirPrimaryButton(
                label: l10n.supportSend,
                isLoading: state.submitting,
                onPressed: state.canSend ? _submit : null,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _form(BuildContext context, NewCaseReady state) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<NewCaseCubit>();
    final body = state.body.trim();
    // Keep the controller in step with the cubit (typing already matches;
    // only a restored or seeded state differs here).
    if (_bodyController.text != state.body) {
      _bodyController.value = TextEditingValue(
        text: state.body,
        selection: TextSelection.collapsed(offset: state.body.length),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.supportType,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: Dimens.space8),
          Wrap(
            spacing: Dimens.space8,
            runSpacing: Dimens.space8,
            children: [
              for (final type in CaseType.guestSelectable)
                ChoiceChip(
                  label: Text(supportTypeLabel(type, l10n)),
                  selected: state.type == type,
                  onSelected: (selected) =>
                      cubit.updateType(selected ? type : null),
                ),
            ],
          ),
          const SizedBox(height: Dimens.space16),
          if (state.bookingId != null || state.propertyId != null)
            _LinkedChip(state: state)
          else
            OutlinedButton.icon(
              onPressed: state.submitting ? null : _pickBooking,
              icon: const Icon(Icons.link),
              label: Text(l10n.supportLinkBooking),
            ),
          const SizedBox(height: Dimens.space16),
          OnAirTextField(
            controller: _bodyController,
            label: l10n.supportDescription,
            maxLines: 6,
            maxLength: 4000,
            errorText: body.isNotEmpty && body.length < 10
                ? l10n.supportDescriptionTooShort
                : null,
            onChanged: cubit.updateBody,
          ),
          const SizedBox(height: Dimens.space16),
          AttachmentStrip(
            draftId: state.draftId,
            attachments: state.attachments,
            onChanged: cubit.updateAttachments,
            picker: context.read<AttachmentPicker>(),
            sanitizer: context.read<ImageSanitizer>(),
            uploader: context.read<PrivateFileUploader>(),
            enabled: state.online && !state.submitting,
          ),
          const SizedBox(height: Dimens.space16),
        ],
      ),
    );
  }
}

/// The removable booking/apartment chip (FR-007).
final class _LinkedChip extends StatelessWidget {
  const _LinkedChip({required this.state});

  final NewCaseReady state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isBooking = state.bookingId != null;
    final label = isBooking
        // The code resolves asynchronously from the booking details; before
        // it lands (or when it cannot) the id itself is shown.
        ? l10n.supportLinkedBooking(state.bookingCode ?? state.bookingId!)
        : l10n.supportLinkedProperty(state.propertyTitle ?? state.propertyId!);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: InputChip(
        avatar: Icon(
          isBooking
              ? Icons.confirmation_number_outlined
              : Icons.apartment_outlined,
          size: 18,
        ),
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 18),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        onDeleted: () => context.read<NewCaseCubit>().unlink(),
      ),
    );
  }
}

/// «اربط بحجز»: the guest's own bookings (code + dates).
final class _BookingLinkSheet extends StatefulWidget {
  const _BookingLinkSheet({required this.repository, required this.onSelected});

  final BookingsRepository repository;
  final ValueChanged<BookingSummary> onSelected;

  @override
  State<_BookingLinkSheet> createState() => _BookingLinkSheetState();
}

final class _BookingLinkSheetState extends State<_BookingLinkSheet> {
  List<BookingSummary>? _bookings;
  AppFailure? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _bookings = null;
    });
    try {
      final current = await widget.repository.listBookings(BookingTab.current);
      final pending = await widget.repository.listBookings(BookingTab.pending);
      final merged = <String, BookingSummary>{
        for (final booking in [...pending.items, ...current.items])
          booking.id: booking,
      };
      if (!mounted) return;
      setState(() => _bookings = merged.values.toList());
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SizedBox(
        height: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                Dimens.screenSide,
                Dimens.space8,
                Dimens.screenSide,
                Dimens.space8,
              ),
              child: Text(
                l10n.supportLinkBooking,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: _error != null
                  ? ErrorView(
                      message: apiErrorMessage(_error!.error, l10n),
                      referenceNumber: _error!.error.requestId,
                      onRetry: _load,
                    )
                  : _bookings == null
                  ? const Center(child: CircularProgressIndicator())
                  : _bookings!.isEmpty
                  ? EmptyView(
                      icon: Icons.luggage_outlined,
                      message: l10n.bookingsEmptyCurrent,
                    )
                  : ListView.builder(
                      itemCount: _bookings!.length,
                      itemBuilder: (context, index) {
                        final booking = _bookings![index];
                        final locale = l10n.localeName;
                        return ListTile(
                          leading: const Icon(
                            Icons.confirmation_number_outlined,
                          ),
                          title: Text(booking.code),
                          subtitle: Text(
                            '${DateOnlyFormatter.dayMonth(booking.stay.checkIn, locale: locale)}'
                            ' – '
                            '${DateOnlyFormatter.dayMonth(booking.stay.checkOut, locale: locale)}',
                          ),
                          onTap: () {
                            widget.onSelected(booking);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

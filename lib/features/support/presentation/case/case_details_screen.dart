import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/files/attachment_picker.dart';
import 'package:on_air/core/files/image_sanitizer.dart';
import 'package:on_air/core/files/private_file_uploader.dart';
import 'package:on_air/design_system/components/attachment_tile.dart';
import 'package:on_air/design_system/components/message_bubble.dart' as design;
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/support/data/mock_support_server.dart';
import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/features/support/presentation/case/case_details_cubit.dart';
import 'package:on_air/features/support/presentation/mock_support_tools_sheet.dart';
import 'package:on_air/features/support/presentation/support_texts.dart';
import 'package:on_air/features/support/presentation/widgets/reply_composer.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class CaseDetailsScreen extends StatefulWidget {
  const CaseDetailsScreen({required this.caseId, super.key});
  final String caseId;

  @override
  State<CaseDetailsScreen> createState() => _CaseDetailsScreenState();
}

final class _CaseDetailsScreenState extends State<CaseDetailsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels < 120) {
      unawaited(context.read<CaseDetailsCubit>().loadOlder());
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CaseDetailsCubit, CaseDetailsState>(
        builder: (context, state) {
          final ready = state is CaseDetailsReady ? state : null;
          return Scaffold(
            appBar: AppBar(
              title: GestureDetector(
                onLongPress: ready == null ? null : () => _showTools(context),
                child: Text(ready?.details.supportCase.code ?? ''),
              ),
              actions: [
                if (ready != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: Dimens.space12,
                    ),
                    child: Center(
                      child: CaseStatusChip(
                        status: supportStatus(ready.details.supportCase.status),
                      ),
                    ),
                  ),
              ],
            ),
            body: _body(context, state),
            bottomNavigationBar: ready != null ? _bottom(context, ready) : null,
          );
        },
      );

  void _showTools(BuildContext context) {
    if (!kDebugMode) return;
    final server = context.read<MockSupportServer?>();
    if (server != null) {
      unawaited(
        showMockSupportToolsSheet(
          context,
          server: server,
          caseId: widget.caseId,
        ),
      );
    }
  }

  Widget _body(BuildContext context, CaseDetailsState state) {
    final l10n = AppLocalizations.of(context);
    if (state is CaseDetailsLoading) return const LoadingView();
    if (state is CaseDetailsNotFound) {
      return EmptyView(
        icon: Icons.search_off_outlined,
        message: l10n.supportCaseNotFound,
        action: TextButton(
          onPressed: () => context.go(AppRoutes.support),
          child: Text(l10n.supportBackToSupport),
        ),
      );
    }
    if (state is CaseDetailsFailed) {
      return ErrorView(
        message: apiErrorMessage(state.error, l10n),
        referenceNumber: state.error.requestId,
        onRetry: context.read<CaseDetailsCubit>().load,
      );
    }
    final ready = state as CaseDetailsReady;
    return RefreshIndicator(
      onRefresh: context.read<CaseDetailsCubit>().refresh,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
        children: [
          if (ready.loadingOlder)
            const Center(child: CircularProgressIndicator()),
          _CaseInfoCard(supportCase: ready.details.supportCase),
          const SizedBox(height: Dimens.space16),
          for (final message in ready.details.messages)
            design.MessageBubble(
              author: message.author == MessageAuthor.guest
                  ? design.MessageAuthor.guest
                  : design.MessageAuthor.onAir,
              body: message.body,
              time: message.createdAt,
              sendState: switch (message.sendState) {
                MessageSendState.sent => design.MessageSendState.sent,
                MessageSendState.sending => design.MessageSendState.sending,
                MessageSendState.failed => design.MessageSendState.failed,
              },
              attachments: [
                for (final attachment in message.attachments)
                  AttachmentTile(
                    kind: attachment.kind.name == 'pdf'
                        ? AttachmentTileKind.pdf
                        : AttachmentTileKind.image,
                    name: attachment.kind.name,
                    sizeLabel: '${(attachment.sizeBytes / 1024).ceil()} KB',
                  ),
              ],
            ),
          const SizedBox(height: Dimens.space16),
        ],
      ),
    );
  }

  Widget? _bottom(BuildContext context, CaseDetailsReady ready) {
    final l10n = AppLocalizations.of(context);
    final supportCase = ready.details.supportCase;
    if (supportCase.status == CaseStatus.closed) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(Dimens.space16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.supportCaseClosed),
              const SizedBox(height: Dimens.space8),
              FilledButton(
                onPressed: () => context.push(
                  Uri(
                    path: AppRoutes.supportNew,
                    queryParameters: supportCase.bookingId == null
                        ? null
                        : {'booking': supportCase.bookingId},
                  ).toString(),
                ),
                child: Text(l10n.supportOpenNewCase),
              ),
            ],
          ),
        ),
      );
    }
    final online = context.watch<ConnectivityCubit>().state.isOnline;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (supportCase.status == CaseStatus.resolved)
          Container(
            width: double.infinity,
            color: context.colors['successContainer'],
            padding: const EdgeInsetsDirectional.all(Dimens.space12),
            child: Text(
              l10n.supportResolvedNotice,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors['onSuccessContainer']),
            ),
          ),
        ReplyComposer(
          draftId: ready.draftId,
          body: ready.body,
          attachments: ready.attachments,
          onBodyChanged: context.read<CaseDetailsCubit>().updateBody,
          onAttachmentsChanged: context
              .read<CaseDetailsCubit>()
              .updateAttachments,
          onSend: () => unawaited(context.read<CaseDetailsCubit>().send()),
          picker: context.read<AttachmentPicker>(),
          sanitizer: context.read<ImageSanitizer>(),
          uploader: context.read<PrivateFileUploader>(),
          online: online,
          submitting: ready.submitting,
        ),
      ],
    );
  }
}

final class _CaseInfoCard extends StatelessWidget {
  const _CaseInfoCard({required this.supportCase});
  final SupportCase supportCase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.info_outline),
        title: Text(supportTypeLabel(supportCase.type, l10n)),
        childrenPadding: const EdgeInsetsDirectional.fromSTEB(
          Dimens.space16,
          0,
          Dimens.space16,
          Dimens.space16,
        ),
        children: [
          if (supportCase.bookingId != null && supportCase.bookingCode != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(
                l10n.supportLinkedBooking(supportCase.bookingCode!),
              ),
              onTap: () => context.push(
                AppRoutes.bookingDetails(supportCase.bookingId!),
              ),
            ),
          if (supportCase.propertyTitle case final title?)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.apartment_outlined),
              title: Text(l10n.supportLinkedProperty(title)),
            ),
        ],
      ),
    );
  }
}

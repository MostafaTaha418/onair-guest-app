import 'package:flutter/material.dart';
import 'package:on_air/core/files/attachment_picker.dart';
import 'package:on_air/core/files/image_sanitizer.dart';
import 'package:on_air/core/files/private_file_uploader.dart';
import 'package:on_air/core/files/upload_limits.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/presentation/widgets/rapid_submit_guard.dart';
import 'package:on_air/features/support/domain/attachment_draft.dart';
import 'package:on_air/features/support/presentation/widgets/attachment_strip.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class ReplyComposer extends StatefulWidget {
  const ReplyComposer({
    required this.draftId,
    required this.body,
    required this.attachments,
    required this.onBodyChanged,
    required this.onAttachmentsChanged,
    required this.onSend,
    required this.picker,
    required this.sanitizer,
    required this.uploader,
    this.limits = const UploadLimits(),
    this.online = true,
    this.submitting = false,
    super.key,
  });

  final String draftId;
  final String body;
  final List<AttachmentDraft> attachments;
  final ValueChanged<String> onBodyChanged;
  final ValueChanged<List<AttachmentDraft>> onAttachmentsChanged;
  final VoidCallback onSend;
  final AttachmentPicker picker;
  final ImageSanitizer sanitizer;
  final PrivateFileUploader uploader;
  final UploadLimits limits;
  final bool online;
  final bool submitting;

  @override
  State<ReplyComposer> createState() => _ReplyComposerState();
}

final class _ReplyComposerState extends State<ReplyComposer> {
  final _guard = RapidSubmitGuard();
  late final TextEditingController _controller = TextEditingController(
    text: widget.body,
  );

  @override
  void didUpdateWidget(ReplyComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.body != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.body,
        selection: TextSelection.collapsed(offset: widget.body.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSend =>
      widget.online &&
      !widget.submitting &&
      widget.body.trim().isNotEmpty &&
      widget.attachments.every((item) => item.state.isUploaded);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(Dimens.space12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AttachmentStrip(
                draftId: widget.draftId,
                attachments: widget.attachments,
                onChanged: widget.onAttachmentsChanged,
                picker: widget.picker,
                sanitizer: widget.sanitizer,
                uploader: widget.uploader,
                limits: widget.limits,
                enabled: widget.online && !widget.submitting,
              ),
              const SizedBox(height: Dimens.space8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !widget.submitting,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 4000,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: l10n.supportReplyHint,
                        counterText: '',
                      ),
                      onChanged: widget.onBodyChanged,
                    ),
                  ),
                  const SizedBox(width: Dimens.space8),
                  Semantics(
                    button: true,
                    label: l10n.supportSend,
                    child: SizedBox.square(
                      dimension: 48,
                      child: IconButton.filled(
                        onPressed: _canSend
                            ? () {
                                if (_guard.tryEnter()) widget.onSend();
                              }
                            : null,
                        icon: widget.submitting
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

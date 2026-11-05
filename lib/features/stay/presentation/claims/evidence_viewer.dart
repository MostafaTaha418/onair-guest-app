import 'package:flutter/material.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/features/stay/domain/damage_claim.dart';
import 'package:on_air/features/stay/presentation/claims/evidence_url_cache.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Full-screen evidence viewer: pinch/zoom only — no download, no share.
final class EvidenceViewer extends StatefulWidget {
  const EvidenceViewer({
    required this.evidence,
    required this.initialIndex,
    required this.cache,
    super.key,
  });

  final List<EvidenceRef> evidence;
  final int initialIndex;
  final EvidenceUrlCache cache;

  @override
  State<EvidenceViewer> createState() => _EvidenceViewerState();
}

final class _EvidenceViewerState extends State<EvidenceViewer> {
  late int _page = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.claimEvidencePhoto('${_page + 1}', '${widget.evidence.length}'),
        ),
        leading: IconButton(
          icon: const Icon(AppIcons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: widget.initialIndex),
        onPageChanged: (page) => setState(() => _page = page),
        itemCount: widget.evidence.length,
        itemBuilder: (context, index) => FutureBuilder<Uri>(
          future: widget.cache.urlFor(widget.evidence[index].attachmentId),
          builder: (context, snapshot) {
            final uri = snapshot.data;
            if (uri == null) {
              return const Center(
                child: Icon(AppIcons.imageNotSupportedOutlined),
              );
            }
            return InteractiveViewer(
              child: Center(
                child: Image.network(
                  uri.toString(),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Icon(AppIcons.imageNotSupportedOutlined),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

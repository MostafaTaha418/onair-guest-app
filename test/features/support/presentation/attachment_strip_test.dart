import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/files/attachment_picker.dart';
import 'package:on_air/core/files/image_sanitizer.dart';
import 'package:on_air/core/files/private_file_uploader.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/support/domain/attachment_draft.dart';
import 'package:on_air/features/support/presentation/widgets/attachment_strip.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Signs every upload with its own attachment id, like the real Node signer.
final class _Signer implements UploadSigner {
  int calls = 0;
  @override
  Future<UploadSignResponse> sign(UploadSignRequest request) async {
    calls++;
    return UploadSignResponse(
      attachmentId: 'attachment-$calls',
      uploadUrl: Uri.parse('https://upload.test/object'),
    );
  }
}

/// Every put waits on its gate. Opening a gate while the token was
/// cancelled reproduces the real client's requestCancelled abort, and
/// [ticks] hands the test extra mid-flight progress callbacks.
final class _GatedPut implements RawPutClient {
  final gates = <Completer<void>>[];
  final ticks = <void Function()>[];
  bool failAfterGate = false;

  @override
  Future<void> put({
    required Uri url,
    required String filePath,
    required String mime,
    required int sizeBytes,
    required CancelToken cancelToken,
    required void Function(int sent, int total) onProgress,
  }) async {
    onProgress(1, 4);
    final gate = gates.isNotEmpty ? gates.removeAt(0) : Completer<void>();
    ticks.add(() => onProgress(3, 4));
    await gate.future;
    if (failAfterGate) {
      throw DioException(
        requestOptions: RequestOptions(path: url.toString()),
        type: DioExceptionType.connectionError,
      );
    }
    if (cancelToken.isCancelled) {
      throw DioException.requestCancelled(
        requestOptions: RequestOptions(path: url.toString()),
        reason: cancelToken.cancelError,
      );
    }
    onProgress(4, 4);
  }
}

/// The compress step waits on its gate and writes a real file with sync
/// IO, so `uploader.abandon` has something to delete in any zone.
final class _GatedCompressor implements CompressorPort {
  Completer<void>? compressGate;
  int compressCalls = 0;

  @override
  Future<ImageDimensions> dimensions(String path) async =>
      const ImageDimensions(4, 4);

  @override
  Future<CompressedImage> compress(CompressRequest request) async {
    compressCalls++;
    final gate = compressGate;
    if (gate != null) {
      compressGate = null;
      await gate.future;
    }
    final file = File(request.targetPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(List.filled(8, 1));
    return CompressedImage(
      path: file.path,
      sizeBytes: 8,
      width: 4,
      height: 4,
    );
  }
}

/// Holds the strip's list, forwarding every onChanged emission so tests
/// can inspect what the parent actually received, in order.
final class _Harness extends StatefulWidget {
  const _Harness({required this.child, required this.changes});

  final Widget Function(
    BuildContext context,
    List<AttachmentDraft> items,
    ValueChanged<List<AttachmentDraft>> onChanged,
  )
  child;
  final ValueChanged<List<AttachmentDraft>> changes;

  @override
  State<_Harness> createState() => _HarnessState();
}

final class _HarnessState extends State<_Harness> {
  List<AttachmentDraft> _items = const [];

  void _onChanged(List<AttachmentDraft> value) {
    widget.changes(value);
    setState(() => _items = List.of(value));
  }

  @override
  Widget build(BuildContext context) =>
      widget.child(context, _items, _onChanged);
}

/// A picker handing out its queue one file per pick call.
final class _QueuePick implements AttachmentPicker {
  _QueuePick(this.queue);

  final List<PickedFile> queue;

  @override
  Future<List<PickedFile>> pickCamera() async => [queue.removeAt(0)];

  @override
  Future<List<PickedFile>> pickGallery({required int max}) async => [
    queue.removeAt(0),
  ];

  @override
  Future<List<PickedFile>> pickPdf() async => [queue.removeAt(0)];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppLocalizations l10n;
  late _Signer signer;
  late _GatedPut put;
  late _GatedCompressor compressor;
  late _QueuePick picker;
  late Directory temp;
  final changes = <List<AttachmentDraft>>[];

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() {
    signer = _Signer();
    put = _GatedPut();
    compressor = _GatedCompressor();
    picker = _QueuePick([]);
    temp = Directory.systemTemp.createTempSync('onair-strip-test-');
    changes.clear();
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  PickedFile picked([String name = 'photo.jpg']) => PickedFile(
    path: '${temp.path}${Platform.pathSeparator}$name',
    name: name,
    sizeBytes: 8,
    mime: 'image/jpeg',
  );

  /// Real IO (the sanitizer's temp file work) never completes under the
  /// fake async zone, so pipeline spans run inside [tester.runAsync].
  Future<void> waitFor(bool Function() condition) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!condition() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  /// Lets real-zone microtasks run until the emission list stops
  /// growing (the pipeline spans live in runAsync's real event loop).
  Future<void> settle() async {
    var stable = 0;
    var seen = changes.length;
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (stable < 2 && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (changes.length == seen) {
        stable++;
      } else {
        stable = 0;
        seen = changes.length;
      }
    }
  }

  Future<void> pumpStrip(WidgetTester tester) async {
    // The pick sheet's options sit below the 800×600 default surface
    // (device-CI viewport rule).
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OnAirTheme.light,
        home: Scaffold(
          body: _Harness(
            changes: changes.add,
            child: (context, items, onChanged) => AttachmentStrip(
              draftId: 'draft-1',
              attachments: items,
              onChanged: onChanged,
              picker: picker,
              sanitizer: ImageSanitizer(
                compressor: compressor,
                temporaryDirectory: () async => temp,
              ),
              uploader: PrivateFileUploader(
                signer: signer,
                putClient: put,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pick(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.tap(find.text(l10n.supportAttach));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.supportAttachGallery).last);
      // The pipeline emits preparing → uploading in several batches;
      // wait for the uploading tile instead of counting emissions.
      await waitFor(
        () => changes.any(
          (batch) => batch.any(
            (item) => item.state.phase == AttachmentUploadPhase.uploading,
          ),
        ),
      );
      await settle();
    });
    await tester.pump();
  }

  testWidgets(
    'removing during an upload stays removed when the upload reports cancelled',
    (tester) async {
      final gate = Completer<void>();
      put.gates.add(gate);
      picker.queue.add(picked());
      await pumpStrip(tester);
      await pick(tester);
      expect(changes.last, hasLength(1));

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(changes.last, isEmpty);

      // The uploader reports the cancellation; the tile must not return.
      await tester.runAsync(() async {
        gate.complete();
        await settle();
      });
      await tester.pump();

      expect(changes.last, isEmpty);
    },
  );

  testWidgets(
    'removing during sanitizing abandons the prepared file and never uploads',
    (tester) async {
      final gate = Completer<void>();
      compressor.compressGate = gate;
      picker.queue.add(picked());
      await pumpStrip(tester);
      // Only the explicit preparing insert lands; compress is held.
      await tester.runAsync(() async {
        await tester.tap(find.text(l10n.supportAttach));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.supportAttachGallery).last);
        await waitFor(() => compressor.compressCalls == 1);
      });
      await tester.pump();
      expect(changes.last, hasLength(1));
      expect(compressor.compressCalls, 1);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(changes.last, isEmpty);

      // Sanitizing finishes after the removal: no upload may start and
      // the prepared file must be dropped.
      await tester.runAsync(() async {
        gate.complete();
        await settle();
      });
      await tester.pump();

      expect(changes.last, isEmpty);
      expect(signer.calls, 0);
      expect(
        temp.listSync().whereType<File>(),
        isEmpty,
        reason: 'abandon must delete the prepared file',
      );
    },
  );

  testWidgets(
    'two concurrent upload updates land in one emitted list',
    (tester) async {
      final first = Completer<void>();
      final second = Completer<void>();
      put.gates.addAll([first, second]);
      picker.queue.addAll([picked('a.jpg'), picked('b.jpg')]);
      await pumpStrip(tester);
      await pick(tester);
      expect(changes.last, hasLength(1));

      await tester.runAsync(() async {
        await tester.tap(find.text(l10n.supportAttach));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.supportAttachGallery).last);
        await waitFor(
          () =>
              changes.last.length == 2 &&
              changes.last.every(
                (item) => item.state.phase == AttachmentUploadPhase.uploading,
              ),
        );
        await settle();
      });
      await tester.pump();
      expect(changes.last, hasLength(2));

      // One burst for both events: the uploaded tick of the first and
      // the progress tick of the second, without a rebuild between them.
      await tester.runAsync(() async {
        first.complete();
        put.ticks.last();
        await settle();
      });
      await tester.pump();

      final last = changes.last;
      expect(last, hasLength(2));
      expect(last[0].state.phase, AttachmentUploadPhase.uploaded);
      expect(last[1].state.phase, AttachmentUploadPhase.uploading);
      // The second tile carries the mid-flight tick (3/4), proving its
      // update was not clobbered by the first one's.
      expect(last[1].state.progress, .75);
      // The second gate is never opened: the tile stays uploading.
      expect(second.isCompleted, isFalse);
    },
  );

  testWidgets('retry of a failed tile uploads again', (tester) async {
    put.failAfterGate = true;
    final failing = Completer<void>();
    put.gates.add(failing);
    picker.queue.add(picked());
    await pumpStrip(tester);
    await pick(tester);
    expect(changes.last.single.state.phase, AttachmentUploadPhase.uploading);

    await tester.runAsync(() async {
      failing.complete();
      await settle();
    });
    await tester.pump();
    expect(changes.last.single.state.phase, AttachmentUploadPhase.failed);

    // A fresh gate for the retried upload, which runs the whole
    // sanitize pipeline again.
    final retried = Completer<void>();
    put.failAfterGate = false;
    put.gates.add(retried);
    await tester.runAsync(() async {
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      await settle();
    });
    await tester.pump();
    expect(changes.last, hasLength(1));

    await tester.runAsync(() async {
      retried.complete();
      await settle();
    });
    await tester.pump();

    expect(changes.last.single.state.phase, AttachmentUploadPhase.uploaded);
    expect(signer.calls, 2);
  });
}

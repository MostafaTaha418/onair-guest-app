@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/files/attachment_picker.dart';
import 'package:on_air/core/files/image_sanitizer.dart';
import 'package:on_air/core/files/private_file_uploader.dart';
import 'package:on_air/core/files/upload_limits.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/support/domain/attachment_draft.dart';
import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/features/support/presentation/new_case/new_case_cubit.dart';
import 'package:on_air/features/support/presentation/new_case/new_case_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_support_files.dart';
import '../../../helpers/fake_support_repository.dart';

void main() {
  AttachmentDraft tile(
    String id, {
    required AttachmentUploadState state,
    AttachmentKind kind = AttachmentKind.image,
    int sizeBytes = 245760,
  }) => AttachmentDraft(
    localId: id,
    kind: kind,
    displayName: kind == AttachmentKind.pdf ? 'invoice.pdf' : 'photo-$id.jpg',
    tempPath: 'photo-$id.jpg',
    sizeBytes: sizeBytes,
    state: state,
  );

  final states = <(String, NewCaseReady, bool)>[
    (
      'prefilled_booking',
      const NewCaseReady(
        draftId: 'golden-draft',
        type: CaseType.booking,
        bookingId: 'b0000000-0000-4000-8000-000000000021',
        bookingCode: 'OA-2042',
        body: 'المكيف مش شغال من يوم الوصول',
      ),
      false,
    ),
    (
      'uploading_failed',
      NewCaseReady(
        draftId: 'golden-draft',
        type: CaseType.payment,
        body: 'الدفع اتحسم مرتين والمكيف كمان مش شغال',
        attachments: [
          tile(
            'a1',
            state: const AttachmentUploadState.uploading(.4),
          ),
          tile(
            'a2',
            state: const AttachmentUploadState.failed(
              UploadFailureReason.network,
            ),
            sizeBytes: 524288,
          ),
        ],
      ),
      false,
    ),
    (
      'ready',
      NewCaseReady(
        draftId: 'golden-draft',
        type: CaseType.propertyIssue,
        body: 'الحوض بيتسرب من الوصلة اللي تحت الحوض',
        attachments: [
          tile('a1', state: const AttachmentUploadState.uploaded('att-1')),
          tile(
            'a2',
            state: const AttachmentUploadState.uploaded('att-2'),
            kind: AttachmentKind.pdf,
            sizeBytes: 524288,
          ),
        ],
      ),
      false,
    ),
    (
      'keyboard',
      const NewCaseReady(
        draftId: 'golden-draft',
        type: CaseType.booking,
        bookingId: 'b0000000-0000-4000-8000-000000000021',
        bookingCode: 'OA-2042',
        body: 'المكيف مش شغال من يوم الوصول',
      ),
      true,
    ),
  ];

  for (final (stateName, state, keyboard) in states) {
    for (final (themeName, themeMode) in [
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ]) {
      for (final (localeName, locale) in [
        ('ar_rtl', const Locale('ar')),
        ('en_ltr', const Locale('en')),
      ]) {
        for (final (scaleName, textScale) in [
          ('1_0', 1.0),
          ('1_3', 1.3),
        ]) {
          for (final width in [320.0, 800.0]) {
            final widthName = width.toInt();
            final variant =
                '${themeName}_${localeName}_${scaleName}_$widthName';
            unawaited(
              goldenTest(
                'new case — $stateName $variant',
                fileName: 'new_case_${stateName}_$variant',
                constraints: BoxConstraints(
                  maxWidth: width + 40,
                  maxHeight: 920,
                ),
                pumpBeforeTest: (tester) async {
                  await tester.pump();
                  await tester.pump(const Duration(milliseconds: 300));
                },
                builder: () => GoldenTestScenario(
                  name: '$stateName/$variant',
                  child: _surface(
                    state,
                    themeMode: themeMode,
                    locale: locale,
                    textScale: textScale,
                    width: width,
                    keyboard: keyboard,
                  ),
                ),
              ),
            );
          }
        }
      }
    }
  }
}

Widget _surface(
  NewCaseReady state, {
  required ThemeMode themeMode,
  required Locale locale,
  required double textScale,
  required double width,
  required bool keyboard,
}) {
  final cubit = NewCaseCubit.seeded(
    repository: FakeSupportRepository(),
    state: state,
  );
  return SizedBox(
    width: width,
    height: 844,
    child: MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AttachmentPicker>.value(
          value: const EmptyAttachmentPicker(),
        ),
        RepositoryProvider<ImageSanitizer>.value(value: fakeSupportSanitizer()),
        RepositoryProvider<PrivateFileUploader>.value(
          value: fakeSupportUploader,
        ),
      ],
      child: BlocProvider<NewCaseCubit>.value(
        value: cubit,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: OnAirTheme.light,
          darkTheme: OnAirTheme.dark,
          themeMode: themeMode,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
              viewInsets: keyboard
                  ? const EdgeInsets.only(bottom: 280)
                  : EdgeInsets.zero,
            ),
            child: child!,
          ),
          home: const NewCaseScreen(),
        ),
      ),
    ),
  );
}

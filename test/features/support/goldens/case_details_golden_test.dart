@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/files/attachment_picker.dart';
import 'package:on_air/core/files/image_sanitizer.dart';
import 'package:on_air/core/files/private_file_uploader.dart';
import 'package:on_air/core/files/upload_limits.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/support/data/mock_support_server.dart';
import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/features/support/presentation/case/case_details_cubit.dart';
import 'package:on_air/features/support/presentation/case/case_details_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_support_files.dart';
import '../../../helpers/fake_support_repository.dart';

void main() {
  final base = sampleDetails();
  final conversation = base.copyWith(
    messages: [
      ...base.messages,
      CaseMessage(
        id: 'm-attachment',
        author: MessageAuthor.guest,
        body: 'دي صورة المشكلة والملف',
        createdAt: DateTime.utc(2026, 11, 16, 11),
        attachments: const [
          AttachmentRef(
            id: 'attachment-image',
            kind: AttachmentKind.image,
            sizeBytes: 245760,
            width: 1200,
            height: 800,
          ),
          AttachmentRef(
            id: 'attachment-pdf',
            kind: AttachmentKind.pdf,
            sizeBytes: 524288,
          ),
        ],
      ),
    ],
  );

  Widget surface(
    CaseDetails details, {
    required ThemeMode themeMode,
    required Locale locale,
    required double textScale,
    required double width,
    bool keyboard = false,
  }) {
    final connectivity = FakeConnectivity().createCubit();
    final cubit = CaseDetailsCubit.seeded(
      caseId: details.supportCase.id,
      repository: FakeSupportRepository(),
      details: details,
    );
    return SizedBox(
      width: width,
      height: 844,
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AttachmentPicker>.value(
            value: const EmptyAttachmentPicker(),
          ),
          RepositoryProvider<ImageSanitizer>.value(
            value: fakeSupportSanitizer(),
          ),
          RepositoryProvider<PrivateFileUploader>.value(
            value: fakeSupportUploader,
          ),
          RepositoryProvider<MockSupportServer?>.value(
            value: MockSupportServer(latency: Duration.zero),
          ),
        ],
        child: BlocProvider<ConnectivityCubit>.value(
          value: connectivity,
          child: BlocProvider<CaseDetailsCubit>.value(
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
              home: CaseDetailsScreen(caseId: details.supportCase.id),
            ),
          ),
        ),
      ),
    );
  }

  final states = <(String, CaseDetails, bool)>[
    ('conversation', conversation, false),
    ('resolved', sampleDetails(status: CaseStatus.resolved), false),
    ('closed', sampleDetails(status: CaseStatus.closed), false),
    ('keyboard', sampleDetails(), true),
  ];
  for (final (stateName, details, keyboard) in states) {
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
                'case details — $stateName $variant',
                fileName: 'case_details_${stateName}_$variant',
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
                  child: surface(
                    details,
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

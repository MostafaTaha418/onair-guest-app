@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/brand/on_air_logo.dart';
import 'package:on_air/design_system/components/on_air_bottom_nav.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

late ui.Image _coast;

void main() {
  setUpAll(() async {
    Future<void> loadFont(String family, String path) async {
      final bytes = await File(path).readAsBytes();
      await (FontLoader(
        family,
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }

    await loadFont('Cairo', 'assets/fonts/cairo/Cairo-Regular.ttf');
    await loadFont('Cairo', 'assets/fonts/cairo/Cairo-Bold.ttf');
    await loadFont(
      'packages/cupertino_icons/CupertinoIcons',
      await _packageAsset('cupertino_icons', 'assets/CupertinoIcons.ttf'),
    );
    await loadFont(
      'packages/lucide_icons_flutter/Lucide',
      await _packageAsset('lucide_icons_flutter', 'assets/lucide.ttf'),
    );
    final bytes = await File(
      'docs/design_reference/screenshots/current_concept/'
      'WhatsApp Image 2026-11-02 at 9.06.18 PM (3).jpeg',
    ).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    _coast = (await codec.getNextFrame()).image;
  });

  for (final variant in [0, 1, 2]) {
    testWidgets('home design proposal $variant', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        SizedBox(
          width: 360,
          height: 800,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: OnAirTheme.light,
            home: _Proposal(variant: variant),
          ),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byKey(const ValueKey('home-proposal')),
        matchesGoldenFile('goldens/home_option_${variant + 1}.png'),
      );
    });
  }
}

Future<String> _packageAsset(String package, String asset) async {
  final config =
      jsonDecode(await File('.dart_tool/package_config.json').readAsString())
          as Map<String, dynamic>;
  final packages = config['packages'] as List<dynamic>;
  final entry = packages.cast<Map<String, dynamic>>().firstWhere(
    (item) => item['name'] == package,
  );
  final root = Uri.parse('${entry['rootUri']}/');
  return root.resolve(asset).toFilePath();
}

final class _Proposal extends StatelessWidget {
  const _Proposal({required this.variant});

  final int variant;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return RepaintBoundary(
      key: const ValueKey('home-proposal'),
      child: Scaffold(
        backgroundColor: colors.background,
        bottomNavigationBar: OnAirBottomNav(
          currentIndex: 0,
          labels: const ['الرئيسية', 'بحث', 'الحجوزات', 'الإشعارات', 'حسابي'],
          onTap: (_) {},
        ),
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: colors.gradient('authBackground'),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 242,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 42, 16, 0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: OnAirLogo.lockup(
                                  height: 38,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            _round(AppIcons.favorite, colors['favorite']),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      AppIcons.search,
                                      color: colors.textSecondary,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'دور على إقامة مناسبة',
                                      style: _text(
                                        14,
                                        FontWeight.w400,
                                        colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _round(AppIcons.tuneOutlined, colors.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: switch (variant) {
                    0 => _reference(context),
                    1 => _discovery(context),
                    _ => _apartmentsFirst(context),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _reference(BuildContext context) => Column(
    children: [
      _sectionHeader(context, 'اكتشف المناطق', 'عرض الكل'),
      const SizedBox(height: 14),
      _photoCard(
        context,
        height: 305,
        title: 'رأس البر',
        subtitle: 'شقق متاحة بأسعار بالجنيه',
        footer: true,
      ),
      const SizedBox(height: 28),
      _sectionHeader(context, 'شقق مقترحة', 'عرض الكل'),
      const SizedBox(height: 14),
      _photoCard(
        context,
        height: 260,
        title: 'شقة بالقرب من البحر',
        subtitle: 'رأس البر',
        footer: false,
      ),
    ],
  );

  Widget _discovery(BuildContext context) => Column(
    children: [
      _sectionHeader(context, 'وجهات تستاهل الزيارة', 'عرض الكل'),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: _photoCard(
              context,
              height: 218,
              title: 'رأس البر',
              subtitle: '42 شقة',
              footer: false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _photoCard(
              context,
              height: 218,
              title: 'مرسى مطروح',
              subtitle: '18 شقة',
              footer: false,
            ),
          ),
        ],
      ),
      const SizedBox(height: 28),
      _sectionHeader(context, 'شقق مقترحة', 'عرض الكل'),
      const SizedBox(height: 14),
      _photoCard(
        context,
        height: 260,
        title: 'شقة بإطلالة بحرية',
        subtitle: '950 ج.م / الليلة',
        footer: true,
      ),
    ],
  );

  Widget _apartmentsFirst(BuildContext context) => Column(
    children: [
      _sectionHeader(context, 'إقامات مقترحة لك', 'عرض الكل'),
      const SizedBox(height: 14),
      _photoCard(
        context,
        height: 330,
        title: 'شقة بإطلالة بحرية',
        subtitle: '950 ج.م / الليلة',
        footer: true,
      ),
      const SizedBox(height: 28),
      _sectionHeader(context, 'اكتشف المناطق', 'عرض الكل'),
      const SizedBox(height: 14),
      Row(
        children: [
          _chip(context, 'رأس البر'),
          const SizedBox(width: 8),
          _chip(context, 'مرسى مطروح'),
        ],
      ),
    ],
  );

  Widget _sectionHeader(BuildContext context, String title, String action) =>
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: _text(18, FontWeight.w800, context.colors.textPrimary),
            ),
          ),
          Text(
            action,
            style: _text(13, FontWeight.w700, context.colors['textAccent']),
          ),
        ],
      );

  Widget _chip(BuildContext context, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: context.colors.border),
    ),
    child: Text(
      label,
      style: _text(13, FontWeight.w600, context.colors.primary),
    ),
  );

  Widget _photoCard(
    BuildContext context, {
    required double height,
    required String title,
    required String subtitle,
    required bool footer,
  }) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: height,
        color: colors.surface,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _CoastPainter(_coast)),
                  if (!footer)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC07283C)],
                        ),
                      ),
                    ),
                  if (!footer)
                    PositionedDirectional(
                      start: 14,
                      end: 14,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: _text(16, FontWeight.w800, Colors.white),
                          ),
                          Text(
                            subtitle,
                            style: _text(12, FontWeight.w500, Colors.white),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (footer)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: _text(16, FontWeight.w800, colors.primary),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: _text(12, FontWeight.w500, colors.textSecondary),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _round(IconData icon, Color color) => Container(
    width: 52,
    height: 52,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: color, size: 24),
  );

  TextStyle _text(double size, FontWeight weight, Color color) => TextStyle(
    fontFamily: 'Cairo',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.25,
  );
}

final class _CoastPainter extends CustomPainter {
  const _CoastPainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      const Rect.fromLTWH(26, 347, 488, 363),
      Offset.zero & size,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant _CoastPainter oldDelegate) => false;
}

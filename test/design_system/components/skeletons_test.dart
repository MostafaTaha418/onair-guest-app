import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';

void main() {
  Future<void> pumpSkeleton(
    WidgetTester tester, {
    required bool disableAnimations,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OnAirTheme.light,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: ListView(
                children: const [
                  SkeletonBox(height: 100),
                  PropertyCardSkeleton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('animations disabled: no ticker is active', (tester) async {
    await pumpSkeleton(tester, disableAnimations: true);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('animations enabled: the pulse runs', (tester) async {
    await pumpSkeleton(tester, disableAnimations: false);
    expect(tester.binding.transientCallbackCount, greaterThan(0));
  });

  testWidgets('the card skeleton matches the card shape', (tester) async {
    await pumpSkeleton(tester, disableAnimations: true);
    expect(find.byType(SkeletonBox), findsNWidgets(5));
  });
}

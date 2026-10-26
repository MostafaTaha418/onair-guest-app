import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/components/on_air_otp_field.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';

void main() {
  testWidgets('pasted OTP fills six boxes and completes once', (tester) async {
    final completed = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: OnAirTheme.light,
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: OnAirOtpField(onCompleted: completed.add),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(completed, ['123456']);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
  });

  testWidgets('loading button displays a loader and blocks taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: OnAirTheme.light,
        home: Scaffold(
          body: OnAirPrimaryButton(
            label: 'Continue',
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(TextButton));
    expect(taps, 0);
  });
}

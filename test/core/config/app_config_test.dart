import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/app_config.dart';

void main() {
  Map<String, dynamic> base([Map<String, dynamic> extra = const {}]) => {
    'min_build_guest_android': 1,
    'min_build_guest_ios': 2,
    'support_phone': '+201000000000',
    'guest_terms_version': '1',
    ...extra,
  };

  test('parses G4 public config', () {
    final config = AppConfig.fromJson(
      base({
        'support_hours_ar': 'يوميًا',
        'support_hours_en': 'Daily',
        'guest_terms_url_ar': 'https://example.test/ar/terms',
        'guest_terms_url_en': 'https://example.test/en/terms',
        'privacy_url_ar': 'https://example.test/ar/privacy',
        'privacy_url_en': 'https://example.test/en/privacy',
        'upload_limits': {'image_mb': 8, 'pdf_mb': 12, 'max_files': 4},
        'english_enabled': false,
      }),
    );

    expect(config.supportContact.phone, '+201000000000');
    expect(config.supportContact.hours('ar'), 'يوميًا');
    expect(config.supportContact.hours('en'), 'Daily');
    expect(config.legal.termsUrl('ar').toString(), contains('/ar/terms'));
    expect(config.legal.privacyUrl('en').toString(), contains('/en/privacy'));
    expect(config.uploadLimits.imageMb, 8);
    expect(config.uploadLimits.pdfMb, 12);
    expect(config.uploadLimits.maxFiles, 4);
    expect(config.englishEnabled, isFalse);
  });

  test('uses safe defaults and treats a blank phone as unavailable', () {
    final config = AppConfig.fromJson(base({'support_phone': '  '}));
    expect(config.supportContact.phone, isNull);
    expect(config.uploadLimits.imageMb, 10);
    expect(config.uploadLimits.pdfMb, 15);
    expect(config.uploadLimits.maxFiles, 5);
    expect(config.englishEnabled, isTrue);
  });
}

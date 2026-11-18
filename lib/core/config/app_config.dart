import 'package:flutter/foundation.dart';
import 'package:on_air/core/files/upload_limits.dart';

@immutable
final class SupportContact {
  const SupportContact({this.phone, this.hoursAr, this.hoursEn});

  final String? phone;
  final String? hoursAr;
  final String? hoursEn;

  String? hours(String locale) => locale == 'en' ? hoursEn : hoursAr;
}

@immutable
final class LegalLinks {
  const LegalLinks({
    this.termsUrlAr,
    this.termsUrlEn,
    this.privacyUrlAr,
    this.privacyUrlEn,
  });

  final Uri? termsUrlAr;
  final Uri? termsUrlEn;
  final Uri? privacyUrlAr;
  final Uri? privacyUrlEn;

  Uri? termsUrl(String locale) => locale == 'en' ? termsUrlEn : termsUrlAr;
  Uri? privacyUrl(String locale) =>
      locale == 'en' ? privacyUrlEn : privacyUrlAr;
}

@immutable
final class AppConfig {
  const AppConfig({
    required this.minSupportedBuildAndroid,
    required this.minSupportedBuildIos,
    required this.supportPhone,
    required this.currentTermsVersion,
    this.supportContact = const SupportContact(),
    this.legal = const LegalLinks(),
    this.uploadLimits = const UploadLimits(),
    this.englishEnabled = true,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final rawPhone = '${json['support_phone'] ?? ''}'.trim();
    return AppConfig(
      minSupportedBuildAndroid: json['min_build_guest_android'] as int,
      minSupportedBuildIos: json['min_build_guest_ios'] as int,
      supportPhone: rawPhone,
      currentTermsVersion: json['guest_terms_version'] as String,
      supportContact: SupportContact(
        phone: rawPhone.isEmpty ? null : rawPhone,
        hoursAr: _nullableString(json['support_hours_ar']),
        hoursEn: _nullableString(json['support_hours_en']),
      ),
      legal: LegalLinks(
        termsUrlAr: _uri(json['guest_terms_url_ar']),
        termsUrlEn: _uri(json['guest_terms_url_en']),
        privacyUrlAr: _uri(json['privacy_url_ar']),
        privacyUrlEn: _uri(json['privacy_url_en']),
      ),
      uploadLimits: UploadLimits.fromJson(json['upload_limits']),
      englishEnabled: json['english_enabled'] as bool? ?? true,
    );
  }

  final int minSupportedBuildAndroid;
  final int minSupportedBuildIos;
  final String supportPhone;
  final String currentTermsVersion;
  final SupportContact supportContact;
  final LegalLinks legal;
  final UploadLimits uploadLimits;
  final bool englishEnabled;

  static String? _nullableString(Object? value) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? null : text;
  }

  static Uri? _uri(Object? value) {
    final text = _nullableString(value);
    return text == null ? null : Uri.tryParse(text);
  }
}

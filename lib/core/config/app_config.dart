import 'package:flutter/foundation.dart';

@immutable
final class AppConfig {
  const AppConfig({
    required this.minSupportedBuildAndroid,
    required this.minSupportedBuildIos,
    required this.supportPhone,
    required this.currentTermsVersion,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
    minSupportedBuildAndroid: json['min_supported_build_android'] as int,
    minSupportedBuildIos: json['min_supported_build_ios'] as int,
    supportPhone: json['support_phone'] as String,
    currentTermsVersion: json['current_terms_version'] as String,
  );

  final int minSupportedBuildAndroid;
  final int minSupportedBuildIos;
  final String supportPhone;
  final String currentTermsVersion;
}

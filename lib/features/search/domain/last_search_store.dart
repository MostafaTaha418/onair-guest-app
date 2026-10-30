import 'dart:convert';

import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/features/account_gate/application/sign_out_service.dart'
    show SignOutService;
import 'package:on_air/features/search/domain/search_criteria.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The guest's last search, stored as the canonical query string under
/// `last_search_v1` (research R13). Holds no personal data, so it survives
/// sign-out ([SignOutService.preservedPreferenceKeys]).
final class LastSearchStore {
  static const _key = 'last_search_v1';

  Future<void> save(SearchCriteria criteria, String? label) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _key,
        jsonEncode({'q': criteria.toQuery().encodeQuery(), 'label': label}),
      );
    } on Object {
      // The last search is a convenience; never fail the search flow for it.
    }
  }

  Future<({SearchCriteria criteria, String? label})?> load({
    required DateOnly today,
  }) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_key);
      if (raw == null) return null;
      final document = jsonDecode(raw);
      if (document is! Map<String, dynamic>) return null;
      final query = document['q'];
      if (query is! String) return null;
      final label = document['label'];
      return (
        criteria: SearchCriteria.fromQuery(
          Uri(query: query).queryParameters,
          today: today,
        ),
        label: label is String ? label : null,
      );
    } on Object {
      return null;
    }
  }
}

extension on Map<String, String> {
  String encodeQuery() => Uri(queryParameters: isEmpty ? null : this).query;
}

import 'package:flutter/foundation.dart';

/// One published FAQ row, localized by the app from `question_ar/answer_ar`
/// or `question_en/answer_en` (data-model §4). English falls back to Arabic
/// when the server has no translation yet.
@immutable
final class FaqItem {
  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.sortOrder,
  });

  factory FaqItem.fromRow(Map<String, dynamic> row, String locale) {
    final english = locale == 'en';
    final question = english
        ? (row['question_en'] as String? ?? row['question_ar'] as String)
        : row['question_ar'] as String;
    final answer = english
        ? (row['answer_en'] as String? ?? row['answer_ar'] as String)
        : row['answer_ar'] as String;
    return FaqItem(
      id: row['id'] as String,
      question: question,
      answer: answer,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  factory FaqItem.fromJson(Map<String, dynamic> json) => FaqItem(
    id: json['id'] as String,
    question: json['question'] as String,
    answer: json['answer'] as String,
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String question;
  final String answer;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'answer': answer,
    'sort_order': sortOrder,
  };

  @override
  bool operator ==(Object other) =>
      other is FaqItem &&
      other.id == id &&
      other.question == question &&
      other.answer == answer &&
      other.sortOrder == sortOrder;

  @override
  int get hashCode => Object.hash(id, question, answer, sortOrder);
}

/// The public cached FAQ read (data-model §4): personal-data free, so it
/// survives sign-out and works offline with a «قد تكون قديمة» notice.
@immutable
final class FaqSnapshot {
  const FaqSnapshot({
    required this.items,
    required this.fetchedAt,
    required this.locale,
  });

  factory FaqSnapshot.fromJson(Map<String, dynamic> json) => FaqSnapshot(
    items: [
      for (final row in json['items'] as List? ?? const [])
        FaqItem.fromJson(Map<String, dynamic>.from(row as Map)),
    ],
    fetchedAt: DateTime.parse(json['fetched_at'] as String),
    locale: json['locale'] as String? ?? 'ar',
  );

  final List<FaqItem> items;
  final DateTime fetchedAt;
  final String locale;

  Map<String, dynamic> toJson() => {
    'items': [for (final item in items) item.toJson()],
    'fetched_at': fetchedAt.toIso8601String(),
    'locale': locale,
  };
}

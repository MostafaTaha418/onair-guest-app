import 'package:flutter/foundation.dart';

/// One row of the guest's notification center (data-model §10). Text comes
/// from the ARB table by [typeKey]; the server's title/body keys are ignored.
@immutable
final class AppNotification {
  const AppNotification({
    required this.id,
    required this.typeKey,
    required this.category,
    required this.entityType,
    required this.entityId,
    required this.params,
    required this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        typeKey: json['type_key'] as String,
        category: json['category'] as String? ?? '',
        entityType: json['entity_type'] as String? ?? '',
        entityId: json['entity_id'] as String? ?? '',
        params: json['params'] == null
            ? const <String, dynamic>{}
            : Map<String, dynamic>.from(json['params'] as Map),
        readAt: json['read_at'] == null
            ? null
            : DateTime.parse(json['read_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  final String id;
  final String typeKey;
  final String category;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> params;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => readAt == null;

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
    id: id,
    typeKey: typeKey,
    category: category,
    entityType: entityType,
    entityId: entityId,
    params: params,
    readAt: readAt,
    createdAt: createdAt,
  );

  @override
  bool operator ==(Object other) =>
      other is AppNotification &&
      other.id == id &&
      other.typeKey == typeKey &&
      other.category == category &&
      other.entityType == entityType &&
      other.entityId == entityId &&
      mapEquals(other.params, params) &&
      other.readAt == readAt &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    typeKey,
    category,
    entityType,
    entityId,
    readAt,
    createdAt,
  );
}

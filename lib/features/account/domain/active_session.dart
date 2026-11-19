enum SessionPlatform {
  android,
  ios,
  web,
  unknown;

  factory SessionPlatform.fromJson(Object? value) => switch (value) {
    'android' => android,
    'ios' => ios,
    'web' => web,
    _ => unknown,
  };
}

final class ActiveSession {
  const ActiveSession({
    required this.id,
    required this.deviceLabel,
    required this.platform,
    required this.createdAt,
    required this.lastActiveAt,
    required this.isCurrent,
  });

  factory ActiveSession.fromJson(Map<String, dynamic> json) => ActiveSession(
    id: json['id'] as String,
    deviceLabel: (json['device_label'] as String? ?? '').trim(),
    platform: SessionPlatform.fromJson(json['platform']),
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    lastActiveAt: DateTime.parse(json['last_active_at'] as String).toUtc(),
    isCurrent: json['is_current'] as bool? ?? false,
  );

  final String id;
  final String deviceLabel;
  final SessionPlatform platform;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final bool isCurrent;

  bool get usesUnknownDeviceLabel => deviceLabel.isEmpty;

  static List<ActiveSession> sorted(Iterable<ActiveSession> sessions) {
    final result = sessions.toList()
      ..sort((a, b) {
        if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
        return b.lastActiveAt.compareTo(a.lastActiveAt);
      });
    return result;
  }
}

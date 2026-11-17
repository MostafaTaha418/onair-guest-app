enum NotificationChannel { push, email }

final class PreferenceChannel {
  const PreferenceChannel({required this.enabled});

  final bool enabled;
}

final class NotificationPreference {
  const NotificationPreference({
    required this.key,
    required this.labelKey,
    required this.isMandatory,
    required this.channels,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    final key = json['category'] as String? ?? 'unknown';
    final mandatory = json['is_mandatory'] as bool? ?? false;
    final rawChannels = json['channels'];
    final channels = <NotificationChannel, PreferenceChannel>{};
    if (rawChannels is List) {
      for (final raw in rawChannels.whereType<Map<Object?, Object?>>()) {
        final name = raw['channel'];
        final channel = NotificationChannel.values.where(
          (candidate) => candidate.name == name,
        );
        if (channel.isEmpty) continue;
        channels[channel.single] = PreferenceChannel(
          enabled: mandatory || (raw['enabled'] as bool? ?? true),
        );
      }
    } else if (rawChannels is Map) {
      for (final channel in NotificationChannel.values) {
        final raw = rawChannels[channel.name];
        if (raw is bool) {
          channels[channel] = PreferenceChannel(
            enabled: mandatory || raw,
          );
        } else if (raw is Map) {
          channels[channel] = PreferenceChannel(
            enabled: mandatory || (raw['enabled'] as bool? ?? true),
          );
        }
      }
    }
    return NotificationPreference(
      key: key,
      labelKey: categoryLabelKey(key),
      isMandatory: mandatory,
      channels: channels,
    );
  }

  final String key;
  final String labelKey;
  final bool isMandatory;
  final Map<NotificationChannel, PreferenceChannel> channels;

  bool enabled(NotificationChannel channel) =>
      isMandatory || (channels[channel]?.enabled ?? true);

  NotificationPreference withChannel(
    NotificationChannel channel, {
    required bool enabled,
  }) => NotificationPreference(
    key: key,
    labelKey: labelKey,
    isMandatory: isMandatory,
    channels: {
      ...channels,
      channel: PreferenceChannel(enabled: isMandatory || enabled),
    },
  );

  static String categoryLabelKey(String key) => switch (key) {
    'booking' => 'notifCategoryBooking',
    'payment' => 'notifCategoryPayment',
    'support' => 'notifCategorySupport',
    'reminders' => 'notifCategoryReminders',
    'review' => 'notifCategoryReview',
    'account' => 'notifCategoryAccount',
    _ => 'notifCategoryUnknown',
  };
}

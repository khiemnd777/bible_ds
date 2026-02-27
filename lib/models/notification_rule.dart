enum NotificationRuleType {
  dailyTime,
  weeklyTime,
  oneTime;

  static NotificationRuleType fromJson(String raw) {
    switch (raw) {
      case 'daily_time':
        return NotificationRuleType.dailyTime;
      case 'weekly_time':
        return NotificationRuleType.weeklyTime;
      case 'one_time':
        return NotificationRuleType.oneTime;
      default:
        throw FormatException('Unsupported notification type: $raw');
    }
  }
}

class LocalizedText {
  const LocalizedText._({
    this.rawText,
    this.localizedMap = const {},
  });

  final String? rawText;
  final Map<String, String> localizedMap;

  factory LocalizedText.fromJson(dynamic value) {
    if (value is String) {
      return LocalizedText._(rawText: value);
    }
    if (value is Map<String, dynamic>) {
      return LocalizedText._(
        localizedMap: value.map(
          (key, val) => MapEntry(key, (val ?? '').toString()),
        ),
      );
    }
    throw const FormatException(
      'Localized text must be either a string or an object.',
    );
  }

  String resolve(String localeCode) {
    if (rawText != null) return rawText!;
    if (localizedMap.isEmpty) return '';

    final exact = localizedMap[localeCode];
    if (exact != null && exact.isNotEmpty) return exact;

    final languageCode = localeCode.split('_').first;
    final byLanguage = localizedMap[languageCode];
    if (byLanguage != null && byLanguage.isNotEmpty) return byLanguage;

    final fallbackEnUs = localizedMap['en_US'];
    if (fallbackEnUs != null && fallbackEnUs.isNotEmpty) return fallbackEnUs;

    final fallbackEn = localizedMap['en'];
    if (fallbackEn != null && fallbackEn.isNotEmpty) return fallbackEn;

    return localizedMap.values.first;
  }
}

class NotificationRule {
  const NotificationRule({
    required this.id,
    required this.enabled,
    required this.type,
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
    this.weekday,
    this.onlyIfNotCompletedToday = false,
  })  : assert(hour >= 0 && hour <= 23),
        assert(minute >= 0 && minute <= 59);

  final String id;
  final bool enabled;
  final NotificationRuleType type;
  final int? weekday;
  final int hour;
  final int minute;
  final LocalizedText title;
  final LocalizedText body;
  final bool onlyIfNotCompletedToday;

  factory NotificationRule.fromJson(Map<String, dynamic> json) {
    final type = NotificationRuleType.fromJson(json['type'] as String);
    final weekday = (json['weekday'] as num?)?.toInt();
    if (type == NotificationRuleType.weeklyTime &&
        (weekday == null || weekday < 1 || weekday > 7)) {
      throw const FormatException('Weekly notification requires weekday 1..7');
    }

    return NotificationRule(
      id: json['id'] as String,
      enabled: json['enabled'] as bool? ?? true,
      type: type,
      weekday: weekday,
      hour: (json['hour'] as num).toInt(),
      minute: (json['minute'] as num).toInt(),
      title: LocalizedText.fromJson(json['title']),
      body: LocalizedText.fromJson(json['body']),
      onlyIfNotCompletedToday:
          json['onlyIfNotCompletedToday'] as bool? ?? false,
    );
  }
}

class NotificationConfig {
  const NotificationConfig({required this.notifications});

  final List<NotificationRule> notifications;

  factory NotificationConfig.fromJson(Map<String, dynamic> json) {
    final rawRules = json['notifications'] as List<dynamic>? ?? const [];
    return NotificationConfig(
      notifications: rawRules
          .map(
              (item) => NotificationRule.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

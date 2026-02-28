class MonetizationConfig {
  const MonetizationConfig({
    required this.donateMinStreak,
  });

  final int donateMinStreak;

  static const MonetizationConfig defaults = MonetizationConfig(
    donateMinStreak: 15,
  );

  factory MonetizationConfig.fromJson(Map<String, dynamic> json) {
    return MonetizationConfig(
      donateMinStreak: (json['donate_min_streak'] as num?)?.toInt() ??
          defaults.donateMinStreak,
    );
  }
}

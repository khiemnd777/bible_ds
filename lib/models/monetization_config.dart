class MonetizationConfig {
  const MonetizationConfig({
    required this.enableDonate,
    required this.donateMinStreak,
  });

  final bool enableDonate;
  final int donateMinStreak;

  static const MonetizationConfig defaults = MonetizationConfig(
    enableDonate: false,
    donateMinStreak: 15,
  );

  factory MonetizationConfig.fromJson(Map<String, dynamic> json) {
    return MonetizationConfig(
      enableDonate: json['enable_donate'] as bool? ?? defaults.enableDonate,
      donateMinStreak: (json['donate_min_streak'] as num?)?.toInt() ??
          defaults.donateMinStreak,
    );
  }
}

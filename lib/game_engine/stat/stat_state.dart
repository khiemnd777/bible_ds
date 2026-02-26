class StatState {
  final int faith;
  final int love;
  final int humility;
  final int wisdom;
  final int pride;

  const StatState({
    required this.faith,
    required this.love,
    required this.humility,
    required this.wisdom,
    required this.pride,
  });

  factory StatState.initial() {
    return const StatState(
      faith: 50,
      love: 50,
      humility: 50,
      wisdom: 50,
      pride: 50,
    );
  }

  StatState apply(String stat, int delta) {
    switch (stat) {
      case 'faith':
        return copyWith(faith: _clamp(faith + delta));
      case 'love':
        return copyWith(love: _clamp(love + delta));
      case 'humility':
        return copyWith(humility: _clamp(humility + delta));
      case 'wisdom':
        return copyWith(wisdom: _clamp(wisdom + delta));
      case 'pride':
        return copyWith(pride: _clamp(pride + delta));
      default:
        return this;
    }
  }

  StatState copyWith({
    int? faith,
    int? love,
    int? humility,
    int? wisdom,
    int? pride,
  }) {
    return StatState(
      faith: faith ?? this.faith,
      love: love ?? this.love,
      humility: humility ?? this.humility,
      wisdom: wisdom ?? this.wisdom,
      pride: pride ?? this.pride,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'faith': faith,
      'love': love,
      'humility': humility,
      'wisdom': wisdom,
      'pride': pride,
    };
  }

  factory StatState.fromJson(Map<String, dynamic> json) {
    return StatState(
      faith: _readWithFallback(json, 'faith'),
      love: _readWithFallback(json, 'love'),
      humility: _readWithFallback(json, 'humility'),
      wisdom: _readWithFallback(json, 'wisdom'),
      pride: _readWithFallback(json, 'pride'),
    );
  }

  static int _readWithFallback(Map<String, dynamic> json, String key) {
    final value = (json[key] as num?)?.toInt() ?? 50;
    return _clamp(value);
  }

  static int _clamp(int value) {
    if (value < 0) return 0;
    if (value > 100) return 100;
    return value;
  }
}

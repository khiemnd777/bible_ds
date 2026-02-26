enum GamePhase {
  scenario,
  outcome,
  reflection,
  summary,
}

enum GameStat {
  faith,
  love,
  obedience,
  humility,
  wisdom,
  fear,
  pride,
}

extension GameStatKey on GameStat {
  String get key => switch (this) {
        GameStat.faith => 'faith',
        GameStat.love => 'love',
        GameStat.obedience => 'obedience',
        GameStat.humility => 'humility',
        GameStat.wisdom => 'wisdom',
        GameStat.fear => 'fear',
        GameStat.pride => 'pride',
      };

  static GameStat? fromKey(String key) {
    for (final stat in GameStat.values) {
      if (stat.key == key) return stat;
    }
    return null;
  }
}

class StatState {
  final Map<GameStat, int> values;

  const StatState({required this.values});

  factory StatState.initial() {
    return StatState(
      values: {
        for (final stat in GameStat.values) stat: 50,
      },
    );
  }

  int valueOf(GameStat stat) => values[stat] ?? 50;

  StatState copyWith({
    Map<GameStat, int>? values,
  }) {
    return StatState(values: values ?? this.values);
  }

  Map<String, dynamic> toJson() {
    return {
      for (final entry in values.entries) entry.key.key: entry.value,
    };
  }

  factory StatState.fromJson(Map<String, dynamic> json) {
    final map = <GameStat, int>{};
    for (final stat in GameStat.values) {
      map[stat] = (json[stat.key] as num?)?.toInt() ?? 50;
    }
    return StatState(values: map);
  }
}

class ProgressState {
  final String currentDayKey;
  final String assignedSceneId;
  final int streak;
  final String? lastPlayedDayKey;
  final bool completedToday;
  final int dayOffset;

  const ProgressState({
    required this.currentDayKey,
    required this.assignedSceneId,
    required this.streak,
    required this.lastPlayedDayKey,
    required this.completedToday,
    required this.dayOffset,
  });

  factory ProgressState.initial() {
    return const ProgressState(
      currentDayKey: '',
      assignedSceneId: '',
      streak: 0,
      lastPlayedDayKey: null,
      completedToday: false,
      dayOffset: 0,
    );
  }

  ProgressState copyWith({
    String? currentDayKey,
    String? assignedSceneId,
    int? streak,
    String? lastPlayedDayKey,
    bool? completedToday,
    int? dayOffset,
  }) {
    return ProgressState(
      currentDayKey: currentDayKey ?? this.currentDayKey,
      assignedSceneId: assignedSceneId ?? this.assignedSceneId,
      streak: streak ?? this.streak,
      lastPlayedDayKey: lastPlayedDayKey ?? this.lastPlayedDayKey,
      completedToday: completedToday ?? this.completedToday,
      dayOffset: dayOffset ?? this.dayOffset,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentDayKey': currentDayKey,
      'assignedSceneId': assignedSceneId,
      'streak': streak,
      'lastPlayedDayKey': lastPlayedDayKey,
      'completedToday': completedToday,
      'dayOffset': dayOffset,
    };
  }

  factory ProgressState.fromJson(Map<String, dynamic> json) {
    return ProgressState(
      currentDayKey: json['currentDayKey'] as String? ?? '',
      assignedSceneId: json['assignedSceneId'] as String? ?? '',
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      lastPlayedDayKey: json['lastPlayedDayKey'] as String?,
      completedToday: json['completedToday'] as bool? ?? false,
      dayOffset: (json['dayOffset'] as num?)?.toInt() ?? 0,
    );
  }
}

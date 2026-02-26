enum GamePhase {
  scenario,
  outcome,
  reflection,
  summary,
  dailySummary,
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

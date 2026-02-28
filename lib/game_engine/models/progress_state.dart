class ProgressState {
  final String lastAssignedDate;
  final String? activeSceneId;
  final String? lastCompletedDate;
  final int currentStreak;
  final int highestStreak;
  final bool todayCompleted;
  final List<String> unlockedSceneIds;

  // Legacy fields kept to avoid unrelated refactors.
  final String currentDayKey;
  final String? lastPlayedDayKey;
  final bool completedToday;
  final int dayOffset;

  const ProgressState({
    required this.lastAssignedDate,
    required this.activeSceneId,
    required this.lastCompletedDate,
    required this.currentStreak,
    required this.highestStreak,
    required this.todayCompleted,
    required this.unlockedSceneIds,
    required this.currentDayKey,
    required this.lastPlayedDayKey,
    required this.completedToday,
    required this.dayOffset,
  });

  factory ProgressState.initial() {
    return const ProgressState(
      lastAssignedDate: '',
      activeSceneId: null,
      lastCompletedDate: null,
      currentStreak: 0,
      highestStreak: 0,
      todayCompleted: false,
      unlockedSceneIds: <String>[],
      currentDayKey: '',
      lastPlayedDayKey: null,
      completedToday: false,
      dayOffset: 0,
    );
  }

  ProgressState copyWith({
    String? lastAssignedDate,
    String? activeSceneId,
    bool clearActiveSceneId = false,
    String? lastCompletedDate,
    bool clearLastCompletedDate = false,
    int? currentStreak,
    int? highestStreak,
    bool? todayCompleted,
    List<String>? unlockedSceneIds,
    String? currentDayKey,
    String? lastPlayedDayKey,
    bool clearLastPlayedDayKey = false,
    bool? completedToday,
    int? dayOffset,
  }) {
    return ProgressState(
      lastAssignedDate: lastAssignedDate ?? this.lastAssignedDate,
      activeSceneId:
          clearActiveSceneId ? null : (activeSceneId ?? this.activeSceneId),
      lastCompletedDate: clearLastCompletedDate
          ? null
          : (lastCompletedDate ?? this.lastCompletedDate),
      currentStreak: currentStreak ?? this.currentStreak,
      highestStreak: highestStreak ?? this.highestStreak,
      todayCompleted: todayCompleted ?? this.todayCompleted,
      unlockedSceneIds: unlockedSceneIds ?? this.unlockedSceneIds,
      currentDayKey: currentDayKey ?? this.currentDayKey,
      lastPlayedDayKey: clearLastPlayedDayKey
          ? null
          : (lastPlayedDayKey ?? this.lastPlayedDayKey),
      completedToday: completedToday ?? this.completedToday,
      dayOffset: dayOffset ?? this.dayOffset,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastAssignedDate': lastAssignedDate,
      'activeSceneId': activeSceneId,
      'lastCompletedDate': lastCompletedDate,
      'currentStreak': currentStreak,
      'highestStreak': highestStreak,
      'todayCompleted': todayCompleted,
      'unlockedSceneIds': unlockedSceneIds,
      'currentDayKey': currentDayKey,
      'lastPlayedDayKey': lastPlayedDayKey,
      'completedToday': completedToday,
      'dayOffset': dayOffset,
      // Legacy compatibility key.
      'streak': currentStreak,
    };
  }

  factory ProgressState.fromJson(Map<String, dynamic> json) {
    final rawUnlockedIds = (json['unlockedSceneIds'] as List<dynamic>? ??
            json['completedSceneIdsToday'] as List<dynamic>? ??
            [])
        .whereType<String>()
        .toList();
    final unlockedIds = <String>[];
    for (final id in rawUnlockedIds) {
      if (!unlockedIds.contains(id)) {
        unlockedIds.add(id);
      }
    }
    final rawActiveId = json['activeSceneId'] as String? ??
        json['lastAssignedSceneId'] as String? ??
        json['assignedSceneId'] as String?;
    final parsedActiveId =
        (rawActiveId == null || rawActiveId.isEmpty) ? null : rawActiveId;

    return ProgressState(
      lastAssignedDate: json['lastAssignedDate'] as String? ??
          json['currentDayKey'] as String? ??
          '',
      activeSceneId: parsedActiveId,
      lastCompletedDate: json['lastCompletedDate'] as String?,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ??
          (json['streak'] as num?)?.toInt() ??
          0,
      highestStreak: (json['highestStreak'] as num?)?.toInt() ??
          (json['maxStreak'] as num?)?.toInt() ??
          (json['currentStreak'] as num?)?.toInt() ??
          (json['streak'] as num?)?.toInt() ??
          0,
      todayCompleted: json['todayCompleted'] as bool? ??
          json['completedToday'] as bool? ??
          false,
      unlockedSceneIds: unlockedIds,
      currentDayKey: json['currentDayKey'] as String? ?? '',
      lastPlayedDayKey: json['lastPlayedDayKey'] as String?,
      completedToday: json['completedToday'] as bool? ?? false,
      dayOffset: (json['dayOffset'] as num?)?.toInt() ?? 0,
    );
  }

  // Legacy compatibility getter for existing UI wiring.
  int get streak => currentStreak;

  Set<String> get unlockedSceneIdSet => unlockedSceneIds.toSet();
}

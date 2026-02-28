import 'package:bible_decision_simulator/game_engine/models/progress_state.dart';

class StreakService {
  const StreakService();

  ProgressState completeDailyScene({
    required ProgressState state,
    required String sceneId,
  }) {
    final today = _todayKey();
    if (sceneId != state.activeSceneId) {
      return state;
    }

    if (state.todayCompleted || state.lastCompletedDate == today) {
      return state;
    }

    final yesterday = _yesterdayKey();
    final nextStreak =
        state.lastCompletedDate == yesterday ? state.currentStreak + 1 : 1;
    final nextHighestStreak =
        nextStreak > state.highestStreak ? nextStreak : state.highestStreak;

    return state.copyWith(
      lastCompletedDate: today,
      currentStreak: nextStreak,
      highestStreak: nextHighestStreak,
      todayCompleted: true,
      completedToday: true,
      lastPlayedDayKey: today,
    );
  }

  String _todayKey() {
    final now = DateTime.now();
    final yyyy = now.year.toString().padLeft(4, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  String _yesterdayKey() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yyyy = yesterday.year.toString().padLeft(4, '0');
    final mm = yesterday.month.toString().padLeft(2, '0');
    final dd = yesterday.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }
}

/*
Test scenario:
Given scenes: [A, B, C]
Day 1:
- active = A
- list = [A]
- complete A => streak = 1
- replay A allowed (no stats, no streak)
- open B blocked
Day 2:
- active = B
- unlocked = [A]
- list = [A, B]
- complete B => streak = 2
Day 3:
- active = C
- unlocked = [A, B]
- list = [A, B, C]
*/

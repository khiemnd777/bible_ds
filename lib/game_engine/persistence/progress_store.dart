import 'package:bible_decision_simulator/game_engine/models/progress_state.dart';
import 'package:bible_decision_simulator/game_engine/stat/stat_state.dart';
import 'package:bible_decision_simulator/game_engine/stat/daily_snapshot.dart';

abstract class ProgressStore {
  Future<StatState> loadStats();
  Future<void> saveStats(StatState state);
  Future<DailySnapshot?> loadDailySnapshot();
  Future<void> saveDailySnapshot(DailySnapshot snapshot);

  Future<ProgressState> loadProgress();
  Future<void> saveProgress(ProgressState state);
}

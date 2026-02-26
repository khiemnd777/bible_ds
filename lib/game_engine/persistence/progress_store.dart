import 'package:bible_decision_simulator/game_engine/models/game_state.dart';

abstract class ProgressStore {
  Future<StatState> loadStats();
  Future<void> saveStats(StatState state);

  Future<ProgressState> loadProgress();
  Future<void> saveProgress(ProgressState state);
}

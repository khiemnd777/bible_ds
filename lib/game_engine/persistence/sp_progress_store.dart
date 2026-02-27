import 'dart:convert';

import 'package:bible_decision_simulator/game_engine/models/progress_state.dart';
import 'package:bible_decision_simulator/game_engine/persistence/progress_repository.dart';
import 'package:bible_decision_simulator/game_engine/persistence/progress_store.dart';
import 'package:bible_decision_simulator/game_engine/stat/stat_state.dart';
import 'package:bible_decision_simulator/game_engine/stat/daily_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpProgressStore implements ProgressStore {
  SpProgressStore(this._prefs)
      : _progressRepository = ProgressRepository(_prefs);

  final SharedPreferences _prefs;
  final ProgressRepository _progressRepository;

  static const _statsKey = 'bds.stats';
  static const _dailySnapshotKey = 'bds.daily_snapshot';

  @override
  Future<ProgressState> loadProgress() async {
    return _progressRepository.load();
  }

  @override
  Future<void> saveProgress(ProgressState state) async {
    await _progressRepository.save(state);
  }

  @override
  Future<StatState> loadStats() async {
    final raw = _prefs.getString(_statsKey);
    if (raw == null || raw.isEmpty) return StatState.initial();
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return StatState.fromJson(map);
  }

  @override
  Future<void> saveStats(StatState state) async {
    await _prefs.setString(_statsKey, jsonEncode(state.toJson()));
  }

  @override
  Future<DailySnapshot?> loadDailySnapshot() async {
    final raw = _prefs.getString(_dailySnapshotKey);
    if (raw == null || raw.isEmpty) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return DailySnapshot.fromJson(map);
  }

  @override
  Future<void> saveDailySnapshot(DailySnapshot snapshot) async {
    await _prefs.setString(_dailySnapshotKey, jsonEncode(snapshot.toJson()));
  }
}

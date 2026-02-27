import 'dart:convert';

import 'package:bible_decision_simulator/game_engine/models/progress_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressRepository {
  ProgressRepository(this._prefs);

  static const _key = 'progress_state';
  static const _legacyKey = 'bds.progress';
  final SharedPreferences _prefs;

  Future<ProgressState> load() async {
    final raw = _prefs.getString(_key) ?? _prefs.getString(_legacyKey);
    if (raw == null || raw.isEmpty) {
      return ProgressState.initial();
    }
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return ProgressState.fromJson(map);
  }

  Future<void> save(ProgressState state) async {
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }
}

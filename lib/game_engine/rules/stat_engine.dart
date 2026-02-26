import 'package:bible_decision_simulator/game_engine/models/content_models.dart';
import 'package:bible_decision_simulator/game_engine/models/game_state.dart';

class StatEngine {
  const StatEngine();

  StatState applyEffects(StatState current, List<StatEffect> effects) {
    final next = Map<GameStat, int>.from(current.values);

    for (final effect in effects) {
      final stat = GameStatKey.fromKey(effect.stat);
      if (stat == null) continue;
      final base = next[stat] ?? 50;
      next[stat] = _clamp(base + effect.delta);
    }

    return current.copyWith(values: next);
  }

  int _clamp(int value) {
    if (value < 0) return 0;
    if (value > 100) return 100;
    return value;
  }
}

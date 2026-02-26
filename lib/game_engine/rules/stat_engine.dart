import 'package:bible_decision_simulator/game_engine/models/content_models.dart';
import 'package:bible_decision_simulator/game_engine/stat/stat_state.dart';

class StatEngine {
  const StatEngine();

  StatState applyEffects(StatState current, List<StatEffect> effects) {
    var next = current;
    for (final effect in effects) {
      next = next.apply(effect.stat, effect.delta);
    }
    return next;
  }
}

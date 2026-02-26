import 'package:bible_decision_simulator/game_engine/models/game_state.dart';

class EndingEngine {
  const EndingEngine();

  String resolveSummary(StatState stats) {
    final wisdom = stats.valueOf(GameStat.wisdom);
    final humility = stats.valueOf(GameStat.humility);
    final pride = stats.valueOf(GameStat.pride);
    final fear = stats.valueOf(GameStat.fear);

    if (wisdom >= 75 && humility >= 70) {
      return 'You walked with discernment and a gentle spirit today.';
    }

    if (pride >= 70 || fear >= 70) {
      return 'Your decisions show tension; tomorrow is a chance to realign your heart.';
    }

    return 'You made meaningful progress and continued the journey with faith.';
  }
}

import 'package:bible_decision_simulator/game_engine/stat/stat_state.dart';

class EndingEngine {
  const EndingEngine();

  String resolveSummary(StatState stats) {
    final wisdom = stats.wisdom;
    final humility = stats.humility;
    final pride = stats.pride;

    if (wisdom >= 75 && humility >= 70) {
      return 'You walked with discernment and a gentle spirit today.';
    }

    if (pride >= 70) {
      return 'Your decisions show tension; tomorrow is a chance to realign your heart.';
    }

    return 'You made meaningful progress and continued the journey with faith.';
  }
}

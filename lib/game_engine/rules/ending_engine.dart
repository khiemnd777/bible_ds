import 'package:bible_decision_simulator/game_engine/stat/stat_state.dart';

class EndingEngine {
  const EndingEngine();

  static const discernmentSummaryKey = 'ending_summary_discernment';
  static const realignSummaryKey = 'ending_summary_realign';
  static const progressSummaryKey = 'ending_summary_progress';

  String resolveSummary(StatState stats) {
    final wisdom = stats.wisdom;
    final humility = stats.humility;
    final pride = stats.pride;

    if (wisdom >= 75 && humility >= 70) {
      return discernmentSummaryKey;
    }

    if (pride >= 70) {
      return realignSummaryKey;
    }

    return progressSummaryKey;
  }
}

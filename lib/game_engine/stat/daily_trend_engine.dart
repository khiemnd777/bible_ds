import 'package:bible_decision_simulator/game_engine/stat/stat_state.dart';

class DailyTrend {
  final Map<String, TrendDirection> directions;

  const DailyTrend(this.directions);
}

enum TrendDirection { up, down, stable }

class DailyTrendEngine {
  const DailyTrendEngine();

  DailyTrend calculateTrend(StatState start, StatState current) {
    TrendDirection calc(int a, int b) {
      if (b - a >= 3) return TrendDirection.up;
      if (a - b >= 3) return TrendDirection.down;
      return TrendDirection.stable;
    }

    return DailyTrend({
      'faith': calc(start.faith, current.faith),
      'love': calc(start.love, current.love),
      'humility': calc(start.humility, current.humility),
      'wisdom': calc(start.wisdom, current.wisdom),
      'pride': calc(start.pride, current.pride),
    });
  }
}

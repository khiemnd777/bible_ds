import 'package:bible_decision_simulator/game_engine/stat/stat_state.dart';

class DailySnapshot {
  final DateTime startDate;
  final StatState startStat;

  const DailySnapshot({
    required this.startDate,
    required this.startStat,
  });

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'startStat': startStat.toJson(),
    };
  }

  factory DailySnapshot.fromJson(Map<String, dynamic> json) {
    final rawDate = json['startDate'] as String?;
    final parsedDate = rawDate == null ? null : DateTime.tryParse(rawDate);
    final rawStat = json['startStat'];

    return DailySnapshot(
      startDate: parsedDate ?? DateTime.now(),
      startStat: rawStat is Map<String, dynamic>
          ? StatState.fromJson(rawStat)
          : StatState.initial(),
    );
  }
}

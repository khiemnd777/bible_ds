import 'package:bible_decision_simulator/game_engine/models/content_models.dart';

class DailyAssignment {
  final String dayKey;
  final String topic;
  final String sceneId;

  const DailyAssignment({
    required this.dayKey,
    required this.topic,
    required this.sceneId,
  });
}

class Scheduler {
  const Scheduler();

  DailyAssignment assignSceneForDay({
    required DateTime now,
    required int dayOffset,
    required List<Scene> scenes,
  }) {
    final effective = DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
    final key = dayKey(effective);

    if (scenes.isEmpty) {
      return DailyAssignment(dayKey: key, topic: 'none', sceneId: '');
    }

    final topics = scenes.map((e) => e.topic).toSet().toList()..sort();
    final daysSinceEpoch = effective.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final weekIndex = daysSinceEpoch ~/ 7;
    final topic = topics[weekIndex % topics.length];

    final candidates = scenes.where((s) => s.topic == topic).toList();
    final pool = candidates.isEmpty ? scenes : candidates;
    final index = daysSinceEpoch % pool.length;

    return DailyAssignment(
      dayKey: key,
      topic: topic,
      sceneId: pool[index].id,
    );
  }

  String dayKey(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  int computeStreak(String? lastPlayedDayKey, String todayDayKey, int currentStreak) {
    if (lastPlayedDayKey == null || lastPlayedDayKey.isEmpty) return 1;
    if (lastPlayedDayKey == todayDayKey) return currentStreak;

    final today = DateTime.parse(todayDayKey);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayKey = dayKey(yesterday);

    if (lastPlayedDayKey == yesterdayKey) {
      return currentStreak + 1;
    }
    return 1;
  }
}

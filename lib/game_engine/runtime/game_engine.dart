import 'package:bible_decision_simulator/game_engine/models/content_models.dart';
import 'package:bible_decision_simulator/game_engine/rules/ending_engine.dart';
import 'package:bible_decision_simulator/game_engine/rules/stat_engine.dart';
import 'package:bible_decision_simulator/game_engine/stat/stat_state.dart';

class ChoiceResolution {
  final StatState nextStats;
  final String outcomeText;
  final String nextTag;

  const ChoiceResolution({
    required this.nextStats,
    required this.outcomeText,
    required this.nextTag,
  });
}

class GameEngine {
  GameEngine({
    required StatEngine statEngine,
    required EndingEngine endingEngine,
  })  : _statEngine = statEngine,
        _endingEngine = endingEngine;

  final StatEngine _statEngine;
  final EndingEngine _endingEngine;

  ChoiceResolution resolveChoice({
    required Choice choice,
    required StatState currentStats,
  }) {
    final nextStats = _statEngine.applyEffects(currentStats, choice.effects);
    return ChoiceResolution(
      nextStats: nextStats,
      outcomeText: choice.outcome.text,
      nextTag: choice.outcome.next,
    );
  }

  ChoiceResolution resolveConversationOutcome({
    required Scene scene,
    required List<String> selectedChoiceIds,
    required StatState currentStats,
    Choice? fallbackChoice,
  }) {
    final conversation = scene.conversation;
    if (conversation.outcomes.isEmpty) {
      final fallback = fallbackChoice?.outcome ??
          const ChoiceOutcome(
            text: '',
            next: 'end',
          );
      return ChoiceResolution(
        nextStats: currentStats,
        outcomeText: fallback.text,
        nextTag: fallback.next,
      );
    }

    final selected = selectedChoiceIds.toSet();
    final sortedOutcomes = [...conversation.outcomes]..sort(
        (a, b) => b.requiredChoiceIds.length.compareTo(
          a.requiredChoiceIds.length,
        ),
      );

    for (final outcome in sortedOutcomes) {
      final matched = outcome.requiredChoiceIds
          .every((choiceId) => selected.contains(choiceId));
      if (matched) {
        return ChoiceResolution(
          nextStats: currentStats,
          outcomeText: outcome.text,
          nextTag: outcome.next,
        );
      }
    }

    final fallback = fallbackChoice?.outcome ??
        const ChoiceOutcome(
          text: '',
          next: 'end',
        );
    return ChoiceResolution(
      nextStats: currentStats,
      outcomeText: fallback.text,
      nextTag: fallback.next,
    );
  }

  ReflectionContent? pickReflection({
    required Scene scene,
    required GameContent content,
    required String? nextTag,
  }) {
    if (nextTag != null && nextTag.startsWith('reflection:')) {
      final id = nextTag.substring('reflection:'.length);
      for (final reflection in content.reflections) {
        if (reflection.id == id) return reflection;
      }
    }

    for (final reflection in content.reflections) {
      if (reflection.topic == scene.topic) return reflection;
    }

    if (content.reflections.isNotEmpty) {
      return content.reflections.first;
    }
    return null;
  }

  String buildEndingSummary(StatState stats) {
    return _endingEngine.resolveSummary(stats);
  }
}

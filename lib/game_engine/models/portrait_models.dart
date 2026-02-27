import 'package:bible_decision_simulator/game_engine/models/content_models.dart';

enum PortraitExpression {
  neutral,
  calm,
  angry,
  joyful,
  sad,
  confident,
}

extension PortraitExpressionExt on PortraitExpression {
  String get key => switch (this) {
        PortraitExpression.neutral => 'neutral',
        PortraitExpression.calm => 'calm',
        PortraitExpression.angry => 'angry',
        PortraitExpression.joyful => 'joyful',
        PortraitExpression.sad => 'sad',
        PortraitExpression.confident => 'confident',
      };

  static PortraitExpression fromString(String value) {
    for (final expression in PortraitExpression.values) {
      if (expression.key == value) return expression;
    }
    return PortraitExpression.neutral;
  }
}

class CharacterRuntimeMap {
  final Character player;
  final Map<String, Character> npcMap;

  CharacterRuntimeMap({
    required this.player,
    required List<Character> npcs,
  }) : npcMap = {
          for (final c in npcs) c.name.toLowerCase(): c,
        };

  Character? resolve(String speaker) {
    final lower = speaker.toLowerCase().trim();

    if (lower == player.name.toLowerCase()) {
      return player;
    }

    return npcMap[lower];
  }
}

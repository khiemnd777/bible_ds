class GameContent {
  final List<Scene> scenes;
  final List<ReflectionContent> reflections;

  const GameContent({
    required this.scenes,
    required this.reflections,
  });

  factory GameContent.fromJson(Map<String, dynamic> json) {
    return GameContent(
      scenes: (json['scenes'] as List<dynamic>? ?? [])
          .map((e) => Scene.fromJson(e as Map<String, dynamic>))
          .toList(),
      reflections: (json['reflections'] as List<dynamic>? ?? [])
          .map((e) => ReflectionContent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Scene {
  final String id;
  final String topic;
  final String title;
  final SceneCharacters characters;
  final SceneConversation conversation;

  const Scene({
    required this.id,
    required this.topic,
    required this.title,
    required this.characters,
    required this.conversation,
  });

  factory Scene.fromJson(Map<String, dynamic> json) {
    final conversationJson =
        json['conversation'] as Map<String, dynamic>? ?? const {};
    return Scene(
      id: json['id'] as String? ?? '',
      topic: json['topic'] as String? ?? 'general',
      title: json['title'] as String? ?? '',
      characters: SceneCharacters.fromJson(
        json['characters'] as Map<String, dynamic>? ?? const {},
      ),
      conversation: SceneConversation.fromJson(conversationJson),
    );
  }

  List<Choice> get initialChoices {
    final firstTurn = firstTurnWithChoices(conversation.startTurnId);
    return firstTurn?.choices ?? const [];
  }

  ConversationTurn? findTurn(String turnId) {
    for (final turn in conversation.turns) {
      if (turn.id == turnId) return turn;
    }
    return null;
  }

  ConversationTurn? firstTurnWithChoices(String? fromTurnId) {
    if (fromTurnId == null || fromTurnId.isEmpty) {
      return null;
    }

    var currentId = fromTurnId;
    final visited = <String>{};
    while (currentId.isNotEmpty && visited.add(currentId)) {
      final turn = findTurn(currentId);
      if (turn == null) return null;
      if (turn.choices.isNotEmpty) return turn;
      if (turn.nextTurnId.isEmpty) return null;
      currentId = turn.nextTurnId;
    }
    return null;
  }

  List<ConversationTurn> leadingTurnsBefore(String turnId) {
    final leading = <ConversationTurn>[];
    var currentId = conversation.startTurnId;
    final visited = <String>{};
    while (currentId.isNotEmpty && visited.add(currentId)) {
      if (currentId == turnId) break;
      final turn = findTurn(currentId);
      if (turn == null) break;
      if (turn.choices.isNotEmpty) break;
      leading.add(turn);
      if (turn.nextTurnId.isEmpty) break;
      currentId = turn.nextTurnId;
    }
    return leading;
  }

  List<ConversationTurn> get introTurns {
    final firstChoiceTurn = firstTurnWithChoices(conversation.startTurnId);
    if (firstChoiceTurn == null) {
      return conversation.turns.where((t) => t.choices.isEmpty).toList();
    }
    return leadingTurnsBefore(firstChoiceTurn.id);
  }
}

class SceneCharacters {
  final Character player;
  final Character npc;

  const SceneCharacters({
    required this.player,
    required this.npc,
  });

  factory SceneCharacters.fromJson(Map<String, dynamic> json) {
    return SceneCharacters(
      player: Character.fromJson(
          json['player'] as Map<String, dynamic>? ?? const {}),
      npc: Character.fromJson(json['npc'] as Map<String, dynamic>? ?? const {}),
    );
  }
}

class Character {
  final String id;
  final String name;
  final String portraitKey;

  const Character({
    required this.id,
    required this.name,
    required this.portraitKey,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      portraitKey: json['portraitKey'] as String? ?? '',
    );
  }
}

class Choice {
  final String id;
  final String text;
  final String playerLine;
  final String intentTag;
  final String actionTag;
  final List<StatEffect> effects;
  final Map<String, String> portraitOverrides;
  final String nextTurnId;
  final ChoiceOutcome outcome;

  const Choice({
    required this.id,
    required this.text,
    required this.playerLine,
    required this.intentTag,
    required this.actionTag,
    required this.effects,
    required this.portraitOverrides,
    required this.nextTurnId,
    required this.outcome,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    final portraitJson =
        json['portraitOverrides'] as Map<String, dynamic>? ?? const {};
    return Choice(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      playerLine: json['playerLine'] as String? ?? '',
      intentTag: json['intentTag'] as String? ?? 'neutral',
      actionTag: json['actionTag'] as String? ?? '',
      effects: (json['effects'] as List<dynamic>? ?? [])
          .map((e) => StatEffect.fromJson(e as Map<String, dynamic>))
          .toList(),
      portraitOverrides: portraitJson.map((k, v) => MapEntry(k, v.toString())),
      nextTurnId: json['nextTurnId'] as String? ?? '',
      outcome: ChoiceOutcome.fromJson(
        json['outcome'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class SceneConversation {
  final String startTurnId;
  final List<ConversationTurn> turns;
  final List<ConversationOutcomeRule> outcomes;

  const SceneConversation({
    required this.startTurnId,
    required this.turns,
    required this.outcomes,
  });

  factory SceneConversation.fromJson(Map<String, dynamic> json) {
    final turns = (json['turns'] as List<dynamic>? ?? [])
        .map((e) => ConversationTurn.fromJson(e as Map<String, dynamic>))
        .toList();

    final startTurnId = json['startTurnId'] as String? ?? '';

    return SceneConversation(
      startTurnId: startTurnId.isEmpty && turns.isNotEmpty
          ? turns.first.id
          : startTurnId,
      turns: turns,
      outcomes: (json['outcomes'] as List<dynamic>? ?? [])
          .map((e) =>
              ConversationOutcomeRule.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ConversationTurn {
  final String id;
  final String speaker;
  final String text;
  final String nextTurnId;
  final List<Choice> choices;

  const ConversationTurn({
    required this.id,
    required this.speaker,
    required this.text,
    required this.nextTurnId,
    required this.choices,
  });

  factory ConversationTurn.fromJson(Map<String, dynamic> json) {
    return ConversationTurn(
      id: json['id'] as String? ?? '',
      speaker: json['speaker'] as String? ?? '',
      text: json['text'] as String? ?? '',
      nextTurnId: json['nextTurnId'] as String? ?? '',
      choices: (json['choices'] as List<dynamic>? ?? [])
          .map((e) => Choice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ConversationOutcomeRule {
  final String id;
  final List<String> requiredChoiceIds;
  final String text;
  final String next;

  const ConversationOutcomeRule({
    required this.id,
    required this.requiredChoiceIds,
    required this.text,
    required this.next,
  });

  factory ConversationOutcomeRule.fromJson(Map<String, dynamic> json) {
    return ConversationOutcomeRule(
      id: json['id'] as String? ?? '',
      requiredChoiceIds: (json['requiredChoiceIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      text: json['text'] as String? ?? '',
      next: json['next'] as String? ?? 'end',
    );
  }
}

class StatEffect {
  final String stat;
  final int delta;

  const StatEffect({
    required this.stat,
    required this.delta,
  });

  factory StatEffect.fromJson(Map<String, dynamic> json) {
    return StatEffect(
      stat: json['stat'] as String? ?? '',
      delta: (json['delta'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChoiceOutcome {
  final String text;
  final String next;

  const ChoiceOutcome({
    required this.text,
    required this.next,
  });

  factory ChoiceOutcome.fromJson(Map<String, dynamic> json) {
    return ChoiceOutcome(
      text: json['text'] as String? ?? '',
      next: json['next'] as String? ?? 'end',
    );
  }
}

class ReflectionContent {
  final String id;
  final String topic;
  final String verseRef;
  final String verseText;
  final List<String> questions;

  const ReflectionContent({
    required this.id,
    required this.topic,
    required this.verseRef,
    required this.verseText,
    required this.questions,
  });

  factory ReflectionContent.fromJson(Map<String, dynamic> json) {
    return ReflectionContent(
      id: json['id'] as String? ?? '',
      topic: json['topic'] as String? ?? 'general',
      verseRef: json['verseRef'] as String? ?? '',
      verseText: json['verseText'] as String? ?? '',
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

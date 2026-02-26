import 'package:bible_decision_simulator/game_engine/models/content_models.dart';

class ContentValidator {
  const ContentValidator();

  List<String> validate(GameContent content) {
    final errors = <String>[];
    final sceneIds = <String>{};
    final reflectionIds = <String>{};

    for (final reflection in content.reflections) {
      if (reflection.id.isEmpty) {
        errors.add('Reflection has empty id.');
      } else if (!reflectionIds.add(reflection.id)) {
        errors.add('Duplicate reflection id: ${reflection.id}');
      }
    }

    for (final scene in content.scenes) {
      if (scene.id.isEmpty) {
        errors.add('Scene has empty id.');
      } else if (!sceneIds.add(scene.id)) {
        errors.add('Duplicate scene id: ${scene.id}');
      }
    }

    for (final scene in content.scenes) {
      final conversation = scene.conversation;
      if (conversation.turns.isEmpty) {
        errors.add('Scene ${scene.id} conversation has no turns.');
        continue;
      }

      final turnIds = <String>{};
      final choiceIds = <String>{};

      if (conversation.startTurnId.isEmpty) {
        errors.add('Scene ${scene.id} conversation has empty startTurnId.');
      }

      for (final turn in conversation.turns) {
        if (turn.id.isEmpty) {
          errors.add('Scene ${scene.id} has conversation turn with empty id.');
        } else if (!turnIds.add(turn.id)) {
          errors.add('Scene ${scene.id} has duplicate turn id: ${turn.id}');
        }

        if (turn.choices.isEmpty && turn.nextTurnId.isEmpty) {
          errors.add(
              'Scene ${scene.id} turn ${turn.id} has no choices and no nextTurnId.');
        }

        _validateChoices(
          errors: errors,
          scene: scene,
          choices: turn.choices,
          reflectionIds: reflectionIds,
          sceneIds: sceneIds,
          prefix: 'Scene ${scene.id} turn ${turn.id}',
        );

        for (final choice in turn.choices) {
          if (choice.id.isNotEmpty && !choiceIds.add(choice.id)) {
            errors.add(
                'Scene ${scene.id} conversation has duplicate choice id: ${choice.id}');
          }
        }
      }

      if (!turnIds.contains(conversation.startTurnId)) {
        errors.add(
            'Scene ${scene.id} conversation startTurnId references missing turn: ${conversation.startTurnId}');
      }

      for (final turn in conversation.turns) {
        if (turn.nextTurnId.isNotEmpty && !turnIds.contains(turn.nextTurnId)) {
          errors.add(
              'Scene ${scene.id} turn ${turn.id} references missing nextTurnId: ${turn.nextTurnId}');
        }
        for (final choice in turn.choices) {
          if (choice.nextTurnId.isNotEmpty &&
              !turnIds.contains(choice.nextTurnId)) {
            errors.add(
                'Scene ${scene.id} turn ${turn.id} choice ${choice.id} references missing nextTurnId: ${choice.nextTurnId}');
          }
        }
      }

      for (final outcome in conversation.outcomes) {
        for (final requiredChoiceId in outcome.requiredChoiceIds) {
          if (!choiceIds.contains(requiredChoiceId)) {
            errors.add(
                'Scene ${scene.id} conversation outcome ${outcome.id} references missing choice id: $requiredChoiceId');
          }
        }
        final nextError = _nextTagError(
          next: outcome.next,
          reflectionIds: reflectionIds,
          sceneIds: sceneIds,
        );
        if (nextError != null) {
          errors.add(
              'Scene ${scene.id} conversation outcome ${outcome.id} $nextError');
        }
      }
    }

    return errors;
  }

  void _validateChoices({
    required List<String> errors,
    required Scene scene,
    required List<Choice> choices,
    required Set<String> reflectionIds,
    required Set<String> sceneIds,
    required String prefix,
  }) {
    for (final choice in choices) {
      if (choice.id.isEmpty) {
        errors.add('$prefix has choice with empty id.');
      }

      final nextError = _nextTagError(
        next: choice.outcome.next,
        reflectionIds: reflectionIds,
        sceneIds: sceneIds,
      );
      if (nextError != null) {
        errors.add('$prefix choice ${choice.id} $nextError');
      }
    }
  }

  String? _nextTagError({
    required String next,
    required Set<String> reflectionIds,
    required Set<String> sceneIds,
  }) {
    if (next.startsWith('reflection:')) {
      final reflectionId = next.substring('reflection:'.length);
      if (!reflectionIds.contains(reflectionId)) {
        return 'references missing reflection: $reflectionId';
      }
      return null;
    }

    if (next.startsWith('scene:')) {
      final sceneId = next.substring('scene:'.length);
      if (!sceneIds.contains(sceneId)) {
        return 'references missing scene: $sceneId';
      }
      return null;
    }

    if (next != 'end') {
      return 'has invalid outcome.next: $next';
    }

    return null;
  }
}

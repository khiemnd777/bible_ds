import 'package:bible_decision_simulator/game_engine/models/content_models.dart';
import 'package:bible_decision_simulator/game_engine/models/portrait_models.dart';

class PortraitResolver {
  const PortraitResolver();

  Map<String, String> resolveScenePortraits(
    Scene scene, {
    String? intentTag,
    Map<String, String> overrides = const {},
  }) {
    final defaultExpression = _expressionFromIntent(intentTag).key;
    final paths = <String, String>{};
    final player = scene.characters.player;
    paths[player.id] = _assetPath(
      player.portraitKey,
      _resolveExpression(
        scene: scene,
        character: player,
        overrides: overrides,
        defaultExpression: defaultExpression,
      ),
    );
    for (final npc in scene.characters.npcs) {
      paths[npc.id] = _assetPath(
        npc.portraitKey,
        _resolveExpression(
          scene: scene,
          character: npc,
          overrides: overrides,
          defaultExpression: defaultExpression,
        ),
      );
    }
    return paths;
  }

  PortraitExpression _expressionFromIntent(String? intentTag) {
    switch (intentTag) {
      case 'peace':
      case 'compassion':
      case 'forgive':
        return PortraitExpression.calm;
      case 'anger':
      case 'rebuke':
        return PortraitExpression.angry;
      case 'courage':
        return PortraitExpression.confident;
      default:
        return PortraitExpression.neutral;
    }
  }

  String _assetPath(String portraitKey, String expression) {
    return 'assets/portraits/$portraitKey/$expression.png';
  }

  String _resolveExpression({
    required Scene scene,
    required Character character,
    required Map<String, String> overrides,
    required String defaultExpression,
  }) {
    final normalized = <String, String>{
      for (final entry in overrides.entries)
        entry.key.trim().toLowerCase(): entry.value.trim(),
    };

    final player = scene.characters.player;
    if (character.id == player.id) {
      return normalized['player'] ??
          normalized[player.id.toLowerCase()] ??
          normalized[player.name.toLowerCase()] ??
          defaultExpression;
    }

    if (scene.characters.npcs.length == 1 && normalized.containsKey('npc')) {
      return normalized['npc']!;
    }

    return normalized[character.id.toLowerCase()] ??
        normalized[character.name.toLowerCase()] ??
        defaultExpression;
  }
}

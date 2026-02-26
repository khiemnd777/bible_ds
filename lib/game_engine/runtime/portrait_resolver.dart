import 'package:bible_decision_simulator/game_engine/models/content_models.dart';
import 'package:bible_decision_simulator/game_engine/models/portrait_models.dart';

class PortraitResolver {
  const PortraitResolver();

  PortraitPair resolveScenePortraits(
    Scene scene, {
    String? intentTag,
    Map<String, String> overrides = const {},
  }) {
    final defaultExpression = _expressionFromIntent(intentTag).key;
    final playerExpression = overrides['player'] ?? defaultExpression;
    final npcExpression = overrides['npc'] ?? 'neutral';

    return PortraitPair(
      leftPath: _assetPath(scene.characters.player.portraitKey, playerExpression),
      rightPath: _assetPath(scene.characters.npc.portraitKey, npcExpression),
      leftName: scene.characters.player.name,
      rightName: scene.characters.npc.name,
    );
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
}

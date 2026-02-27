import 'package:bible_decision_simulator/core/di.dart';
import 'package:bible_decision_simulator/game_engine/models/content_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final scenarioListProvider = Provider<List<Scene>>((ref) {
  final gameState = ref.watch(gameControllerProvider);
  final content = gameState.content;
  if (content == null) return const [];

  final progress = gameState.progress;
  final orderedIds = <String>[];

  for (final id in progress.unlockedSceneIds) {
    if (!orderedIds.contains(id)) {
      orderedIds.add(id);
    }
  }

  final activeSceneId = progress.activeSceneId;
  if (activeSceneId != null &&
      activeSceneId.isNotEmpty &&
      !orderedIds.contains(activeSceneId)) {
    orderedIds.add(activeSceneId);
  }

  final sceneById = <String, Scene>{
    for (final scene in content.scenes) scene.id: scene,
  };

  final filtered = <Scene>[];
  for (final id in orderedIds) {
    final scene = sceneById[id];
    if (scene != null) {
      filtered.add(scene);
    }
  }
  return filtered;
});

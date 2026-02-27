import 'package:bible_decision_simulator/core/di.dart';
import 'package:bible_decision_simulator/core/i18n.dart';
import 'package:bible_decision_simulator/features/game/screens/reflection_screen.dart';
import 'package:bible_decision_simulator/features/game/screens/summary_screen.dart';
import 'package:bible_decision_simulator/game_engine/models/content_models.dart';
import 'package:bible_decision_simulator/game_engine/models/game_state.dart';
import 'package:bible_decision_simulator/game_engine/models/portrait_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameFlowScreen extends ConsumerWidget {
  const GameFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final text = ref.watch(uiTextProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(state.error!),
        ),
      );
    }

    final scene = state.scene;
    if (scene == null) {
      return Center(child: Text(text.noSceneAvailable));
    }

    return switch (state.phase) {
      GamePhase.scenario => ScenarioScreen(
          scene: scene,
          portraits: state.portraits,
          onPickChoice: controller.chooseChoice,
          selectedChoices: state.selectedChoices,
          selectedTurns: state.selectedTurns,
          currentTurnId: state.currentTurnId,
          text: text,
        ),
      GamePhase.outcome => ScenarioScreen(
          scene: scene,
          portraits: state.portraits,
          onPickChoice: controller.chooseChoice,
          selectedChoice: state.selectedChoice,
          selectedChoices: state.selectedChoices,
          selectedTurns: state.selectedTurns,
          currentTurnId: state.currentTurnId,
          outcomeText: state.outcomeText,
          onNextOutcome: controller.goToReflection,
          text: text,
        ),
      GamePhase.reflection => ReflectionScreen(
          reflection: state.reflection,
          onContinue: controller.goToSummary,
          text: text,
        ),
      GamePhase.summary => SummaryScreen(
          stats: state.stats,
          streak: state.progress.streak,
          endingSummary: state.endingSummary,
          scenes: state.content?.scenes ?? const [],
          currentSceneId: state.scene?.id,
          onOpenSceneByIndex: controller.openSceneByIndex,
          text: text,
        ),
      GamePhase.dailySummary => SummaryScreen(
          stats: state.stats,
          streak: state.progress.streak,
          endingSummary: state.endingSummary,
          scenes: state.content?.scenes ?? const [],
          currentSceneId: state.scene?.id,
          onOpenSceneByIndex: controller.openSceneByIndex,
          text: text,
          dailyTrend: state.dailyTrend,
        ),
    };
  }
}

class ScenarioScreen extends StatelessWidget {
  static const double _chatSpacing = 16;
  static TextStyle _conversationTextStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium;
    return (base ?? const TextStyle())
        .copyWith(fontSize: (base?.fontSize ?? 14) + 1);
  }

  const ScenarioScreen({
    super.key,
    required this.scene,
    required this.portraits,
    required this.onPickChoice,
    required this.text,
    required this.selectedChoices,
    required this.selectedTurns,
    required this.currentTurnId,
    this.selectedChoice,
    this.outcomeText,
    this.onNextOutcome,
  });

  final Scene scene;
  final PortraitPair portraits;
  final Future<void> Function(String choiceId) onPickChoice;
  final UiText text;
  final List<Choice> selectedChoices;
  final List<ConversationTurn> selectedTurns;
  final String? currentTurnId;
  final Choice? selectedChoice;
  final String? outcomeText;
  final Future<void> Function()? onNextOutcome;

  bool _isNarratorSpeaker(String speaker) {
    final lowerSpeaker = speaker.toLowerCase();
    return lowerSpeaker.contains('narrator') ||
        lowerSpeaker.contains('dẫn chuyện');
  }

  Widget _buildTurnBubble({
    required ConversationTurn turn,
    required PortraitPair portraits,
    required Color narratorColor,
    required Color npcColor,
    required Color playerColor,
  }) {
    final speaker = turn.speaker.trim().toLowerCase();
    final player = portraits.leftName.trim().toLowerCase();
    final npc = portraits.rightName.trim().toLowerCase();

    if (_isNarratorSpeaker(turn.speaker)) {
      return _NarratorChatBlock(
        speaker: turn.speaker,
        text: turn.text,
        color: narratorColor,
      );
    }

    if (speaker == player) {
      return _PlayerSpeechBubble(
        playerName: portraits.leftName,
        playerAvatarPath: portraits.leftPath,
        text: turn.text,
        color: playerColor,
      );
    }

    if (speaker == npc) {
      return _NpcBubble(
        npcName: portraits.rightName,
        npcAvatarPath: portraits.rightPath,
        text: turn.text,
        color: npcColor,
      );
    }

    // 🔴 Unknown speaker → treat as narrator (safe fallback)
    return _NarratorChatBlock(
      speaker: turn.speaker,
      text: turn.text,
      color: narratorColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final narratorColor = Theme.of(context).colorScheme.tertiaryContainer;
    final npcColor = Theme.of(context).colorScheme.surfaceContainer;
    final playerColor = Theme.of(context).colorScheme.primaryContainer;
    final outcomeColor = Theme.of(context).colorScheme.secondaryContainer;
    final isOutcomeMode = selectedChoice != null && outcomeText != null;
    final currentTurn =
        currentTurnId == null ? null : scene.findTurn(currentTurnId!);
    final introTurns = scene.introTurns;

    return Column(
      children: [
        _SceneHeader(title: scene.title, topic: scene.topic),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...introTurns.map((turn) {
                  return _buildTurnBubble(
                    turn: turn,
                    portraits: portraits,
                    narratorColor: narratorColor,
                    npcColor: npcColor,
                    playerColor: playerColor,
                  );
                }),
                ...selectedTurns.asMap().entries.map(
                      (entry) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTurnBubble(
                            turn: entry.value,
                            portraits: portraits,
                            narratorColor: narratorColor,
                            npcColor: npcColor,
                            playerColor: playerColor,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: ScenarioScreen._chatSpacing),
                            child: _PlayerSpeechBubble(
                              playerName: portraits.leftName,
                              playerAvatarPath: portraits.leftPath,
                              text: selectedChoices[entry.key].playerLine,
                              color: playerColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                if (!isOutcomeMode && currentTurn != null)
                  _buildTurnBubble(
                    turn: currentTurn,
                    portraits: portraits,
                    narratorColor: narratorColor,
                    npcColor: npcColor,
                    playerColor: playerColor,
                  ),
                if (!isOutcomeMode &&
                    currentTurn != null &&
                    currentTurn.choices.isNotEmpty)
                  ...currentTurn.choices.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: ScenarioScreen._chatSpacing),
                          child: _PlayerChoiceBubble(
                            playerName: portraits.leftName,
                            playerAvatarPath: portraits.leftPath,
                            text: entry.value.text,
                            color: playerColor,
                            onTap: () => onPickChoice(entry.value.id),
                            showAvatar: entry.key == 0,
                          ),
                        ),
                      ),
                if (isOutcomeMode)
                  _OutcomeBubble(
                    title: text.outcome,
                    text: outcomeText!,
                    color: outcomeColor,
                  ),
                if (isOutcomeMode)
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: ScenarioScreen._chatSpacing),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onNextOutcome == null
                            ? null
                            : () {
                                onNextOutcome!.call();
                              },
                        child: Text(text.next),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SceneHeader extends StatelessWidget {
  const _SceneHeader({required this.title, required this.topic});

  final String title;
  final String topic;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Chip(label: Text(topic)),
          ],
        ),
      ),
    );
  }
}

class _NarratorChatBlock extends StatelessWidget {
  const _NarratorChatBlock({
    required this.speaker,
    required this.text,
    required this.color,
  });

  final String speaker;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ScenarioScreen._chatSpacing),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$speaker:', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(text, style: ScenarioScreen._conversationTextStyle(context)),
          ],
        ),
      ),
    );
  }
}

class _NpcBubble extends StatelessWidget {
  const _NpcBubble({
    required this.npcName,
    required this.npcAvatarPath,
    required this.text,
    required this.color,
  });

  final String npcName;
  final String npcAvatarPath;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ScenarioScreen._chatSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(path: npcAvatarPath, label: npcName),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text,
                style: ScenarioScreen._conversationTextStyle(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ New: player “speech” bubble for turns where speaker == player name.
/// (Different from _PlayerChoiceBubble which is a button/choice UI.)
class _PlayerSpeechBubble extends StatelessWidget {
  const _PlayerSpeechBubble({
    required this.playerName,
    required this.playerAvatarPath,
    required this.text,
    required this.color,
  });

  final String playerName;
  final String playerAvatarPath;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ScenarioScreen._chatSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text,
                textAlign: TextAlign.left,
                style: ScenarioScreen._conversationTextStyle(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            child: _Avatar(path: playerAvatarPath, label: playerName),
          ),
        ],
      ),
    );
  }
}

class _PlayerChoiceBubble extends StatelessWidget {
  const _PlayerChoiceBubble({
    required this.playerName,
    required this.playerAvatarPath,
    required this.text,
    required this.color,
    required this.onTap,
    required this.showAvatar,
  });

  final String playerName;
  final String playerAvatarPath;
  final String text;
  final Color color;
  final VoidCallback onTap;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              backgroundColor: color,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              text,
              textAlign: TextAlign.left,
              style: ScenarioScreen._conversationTextStyle(context),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 52,
          child: showAvatar
              ? _Avatar(path: playerAvatarPath, label: playerName)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _OutcomeBubble extends StatelessWidget {
  const _OutcomeBubble({
    required this.title,
    required this.text,
    required this.color,
  });

  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ScenarioScreen._chatSpacing),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title:',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Text(text),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.path,
    required this.label,
  });

  final String path;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipOval(
          child: SizedBox(
            width: 40,
            height: 40,
            child: Image.asset(
              path,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  color: Colors.grey.shade300,
                  alignment: Alignment.center,
                  child: const Icon(Icons.person, size: 20),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 52,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

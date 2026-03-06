import 'dart:io';
import 'dart:ui' as ui;

import 'package:bible_decision_simulator/core/di.dart';
import 'package:bible_decision_simulator/features/profile/providers/profile_avatar_provider.dart';
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
    final profileAvatarPath = ref.watch(
      profileAvatarPathProvider.select((value) => value.valueOrNull),
    );

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
          characterMap: state.characterMap ??
              CharacterRuntimeMap(
                player: scene.characters.player,
                npcs: scene.characters.npcs,
              ),
          portraitPaths: state.portraitPaths,
          playerAvatarPathOverride: profileAvatarPath,
          onPickChoice: controller.chooseChoice,
          selectedChoices: state.selectedChoices,
          selectedTurns: state.selectedTurns,
          currentTurnId: state.currentTurnId,
          text: text,
        ),
      GamePhase.outcome => ScenarioScreen(
          scene: scene,
          characterMap: state.characterMap ??
              CharacterRuntimeMap(
                player: scene.characters.player,
                npcs: scene.characters.npcs,
              ),
          portraitPaths: state.portraitPaths,
          playerAvatarPathOverride: profileAvatarPath,
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
          highestStreak: state.progress.highestStreak,
          endingSummary: state.endingSummary,
          scenes: state.content?.scenes ?? const [],
          currentSceneId: state.scene?.id,
          onOpenSceneByIndex: controller.openSceneByIndex,
          onDebugOpenSceneByIndex: controller.debugUnlockAndOpenSceneByIndex,
          text: text,
        ),
      GamePhase.dailySummary => SummaryScreen(
          stats: state.stats,
          streak: state.progress.streak,
          highestStreak: state.progress.highestStreak,
          endingSummary: state.endingSummary,
          scenes: state.content?.scenes ?? const [],
          currentSceneId: state.scene?.id,
          onOpenSceneByIndex: controller.openSceneByIndex,
          onDebugOpenSceneByIndex: controller.debugUnlockAndOpenSceneByIndex,
          text: text,
          dailyTrend: state.dailyTrend,
        ),
    };
  }
}

class ScenarioScreen extends ConsumerStatefulWidget {
  static const double _chatSpacing = 16;
  static final RegExp _avatarPortraitPattern = RegExp(r'^(male|female)_\d+$');
  static TextStyle _conversationTextStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium;
    return (base ?? const TextStyle())
        .copyWith(fontSize: (base?.fontSize ?? 14) + 1);
  }

  const ScenarioScreen({
    super.key,
    required this.scene,
    required this.characterMap,
    required this.portraitPaths,
    required this.onPickChoice,
    required this.text,
    required this.selectedChoices,
    required this.selectedTurns,
    required this.currentTurnId,
    this.playerAvatarPathOverride,
    this.selectedChoice,
    this.outcomeText,
    this.onNextOutcome,
  });

  final Scene scene;
  final CharacterRuntimeMap characterMap;
  final Map<String, String> portraitPaths;
  final Future<void> Function(String choiceId) onPickChoice;
  final UiText text;
  final List<Choice> selectedChoices;
  final List<ConversationTurn> selectedTurns;
  final String? currentTurnId;
  final String? playerAvatarPathOverride;
  final Choice? selectedChoice;
  final String? outcomeText;
  final Future<void> Function()? onNextOutcome;

  @override
  ConsumerState<ScenarioScreen> createState() => _ScenarioScreenState();
}

class _ScenarioScreenState extends ConsumerState<ScenarioScreen> {
  static const String _choiceGuideSeenPrefsKey = 'bds.choice_guide.seen';
  static const Duration _turnRevealDelay = Duration(milliseconds: 200);
  final GlobalKey _firstChoiceBubbleKey = GlobalKey();

  bool _showChoiceGuide = false;
  Rect? _choiceBubbleRect;
  int _visibleTurnCount = 0;
  int _revealGeneration = 0;
  bool _isAwaitingTurnCompletion = false;

  @override
  void initState() {
    super.initState();
    _loadChoiceGuideState();
    _syncVisibleTurns();
  }

  Future<void> _loadChoiceGuideState() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final hasSeenGuide = prefs.getBool(_choiceGuideSeenPrefsKey) ?? false;
    if (!mounted || hasSeenGuide) return;
    setState(() {
      _showChoiceGuide = true;
    });
    _scheduleChoiceRectSync();
  }

  @override
  void didUpdateWidget(covariant ScenarioScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldRestartReveal = oldWidget.scene.id != widget.scene.id ||
        (oldWidget.selectedTurns.isNotEmpty && widget.selectedTurns.isEmpty);
    if (shouldRestartReveal) {
      _revealGeneration += 1;
      _visibleTurnCount = 0;
      _choiceBubbleRect = null;
      _isAwaitingTurnCompletion = false;
    }
    _syncVisibleTurns();
    if (_showChoiceGuide) {
      _scheduleChoiceRectSync();
    }
  }

  List<Duration> _revealDurations() {
    final durations = <Duration>[];

    for (final turn in widget.scene.introTurns) {
      durations.add(_TypingText.durationForText(turn.text));
    }

    var selectedChoiceIndex = 0;
    for (final turn in widget.selectedTurns) {
      durations.add(_TypingText.durationForText(turn.text));
      if (turn.choices.isEmpty || selectedChoiceIndex >= widget.selectedChoices.length) {
        continue;
      }
      durations.add(
        _TypingText.durationForText(widget.selectedChoices[selectedChoiceIndex].playerLine),
      );
      selectedChoiceIndex += 1;
    }

    if (widget.selectedChoice == null && widget.currentTurnId != null) {
      final currentTurn = widget.scene.findTurn(widget.currentTurnId!);
      if (currentTurn != null) {
        durations.add(_TypingText.durationForText(currentTurn.text));
      }
    }

    if (widget.outcomeText != null) {
      durations.add(_TypingText.durationForText(widget.outcomeText!));
    }

    return durations;
  }

  void _syncVisibleTurns() {
    final durations = _revealDurations();
    final targetCount = durations.length;
    if (targetCount <= _visibleTurnCount) {
      if (_visibleTurnCount != targetCount || _isAwaitingTurnCompletion) {
        setState(() {
          _visibleTurnCount = targetCount;
          _isAwaitingTurnCompletion = false;
        });
      }
      return;
    }

    final generation = ++_revealGeneration;
    Future<void>(() async {
      while (mounted &&
          generation == _revealGeneration &&
          _visibleTurnCount < targetCount) {
        final nextIndex = _visibleTurnCount;
        setState(() {
          _visibleTurnCount += 1;
          _isAwaitingTurnCompletion = true;
        });
        final animationDuration = _AnimatedChatEntry.animationDuration >
                durations[nextIndex]
            ? _AnimatedChatEntry.animationDuration
            : durations[nextIndex];
        await Future<void>.delayed(animationDuration + _turnRevealDelay);
        if (!mounted || generation != _revealGeneration) return;
        setState(() {
          _isAwaitingTurnCompletion = false;
        });
      }
    });
  }

  void _scheduleChoiceRectSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_showChoiceGuide) return;
      final bubbleContext = _firstChoiceBubbleKey.currentContext;
      final rootContext = context;
      if (bubbleContext == null) {
        if (_choiceBubbleRect != null) {
          setState(() {
            _choiceBubbleRect = null;
          });
        }
        return;
      }
      final bubbleBox = bubbleContext.findRenderObject() as RenderBox?;
      final rootBox = rootContext.findRenderObject() as RenderBox?;
      if (bubbleBox == null || rootBox == null) return;
      final topLeft = bubbleBox.localToGlobal(Offset.zero, ancestor: rootBox);
      final nextRect = topLeft & bubbleBox.size;
      if (_choiceBubbleRect == nextRect) return;
      setState(() {
        _choiceBubbleRect = nextRect;
      });
    });
  }

  Future<void> _dismissChoiceGuide() async {
    if (!_showChoiceGuide) return;
    setState(() {
      _showChoiceGuide = false;
      _choiceBubbleRect = null;
    });
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_choiceGuideSeenPrefsKey, true);
  }

  bool _isNarratorSpeaker(String speaker) {
    final lowerSpeaker = speaker.toLowerCase();
    return lowerSpeaker.contains('narrator') ||
        lowerSpeaker.contains('dẫn chuyện');
  }

  Widget _buildTurnBubble({
    required ConversationTurn turn,
    required Color narratorColor,
    required Color npcColor,
    required Color playerColor,
    required String playerAvatarPath,
  }) {
    final character = widget.characterMap.resolve(turn.speaker);
    if (character == null) {
      if (_isNarratorSpeaker(turn.speaker)) {
        return _NarratorChatBlock(
          speaker: turn.speaker,
          text: turn.text,
          color: narratorColor,
        );
      }
      throw Exception('Unknown speaker: ${turn.speaker}');
    }

    if (character.id == widget.scene.characters.player.id) {
      return _PlayerSpeechBubble(
        playerName: character.name,
        playerAvatarPath: playerAvatarPath,
        text: turn.text,
        color: playerColor,
      );
    }

    return _NpcBubble(
      npcName: character.name,
      npcAvatarPath: _portraitPathFor(character),
      text: turn.text,
      color: npcColor,
    );
  }

  String _portraitPathFor(Character character) {
    final resolvedPath = widget.portraitPaths[character.id];
    if (resolvedPath != null) {
      return resolvedPath;
    }

    final normalizedKey = character.portraitKey.trim().toLowerCase();
    if (ScenarioScreen._avatarPortraitPattern.hasMatch(normalizedKey)) {
      return 'assets/portraits/$normalizedKey/avatar.png';
    }

    return 'assets/portraits/${character.portraitKey}/neutral.png';
  }

  @override
  Widget build(BuildContext context) {
    final narratorColor = Theme.of(context).colorScheme.tertiaryContainer;
    final npcColor = Theme.of(context).colorScheme.surfaceContainer;
    final playerColor = Theme.of(context).colorScheme.primaryContainer;
    final outcomeColor = Theme.of(context).colorScheme.secondaryContainer;
    final isOutcomeMode = widget.selectedChoice != null && widget.outcomeText != null;
    final currentTurn =
        widget.currentTurnId == null ? null : widget.scene.findTurn(widget.currentTurnId!);
    final introTurns = widget.scene.introTurns;
    final playerPortraitPath = _portraitPathFor(widget.scene.characters.player);
    final playerAvatarPath = widget.playerAvatarPathOverride ?? playerPortraitPath;
    final transcript = <Widget>[];
    var selectedChoiceIndex = 0;

    for (final turn in widget.selectedTurns) {
      transcript.add(
        _buildTurnBubble(
          turn: turn,
          narratorColor: narratorColor,
          npcColor: npcColor,
          playerColor: playerColor,
          playerAvatarPath: playerAvatarPath,
        ),
      );

      if (turn.choices.isEmpty || selectedChoiceIndex >= widget.selectedChoices.length) {
        continue;
      }

      transcript.add(
        Padding(
          padding: const EdgeInsets.only(
            bottom: ScenarioScreen._chatSpacing,
          ),
          child: _PlayerSpeechBubble(
            playerName: widget.scene.characters.player.name,
            playerAvatarPath: playerAvatarPath,
            text: widget.selectedChoices[selectedChoiceIndex].playerLine,
            color: playerColor,
          ),
        ),
      );
      selectedChoiceIndex += 1;
    }

    final revealableTurns = <Widget>[
      ...introTurns.map((turn) {
        return _buildTurnBubble(
          turn: turn,
          narratorColor: narratorColor,
          npcColor: npcColor,
          playerColor: playerColor,
          playerAvatarPath: playerAvatarPath,
        );
      }),
      ...transcript,
      if (!isOutcomeMode && currentTurn != null)
        _buildTurnBubble(
          turn: currentTurn,
          narratorColor: narratorColor,
          npcColor: npcColor,
          playerColor: playerColor,
          playerAvatarPath: playerAvatarPath,
        ),
      if (isOutcomeMode)
        _OutcomeBubble(
          title: widget.text.outcome,
          text: widget.outcomeText!,
          color: outcomeColor,
        ),
    ];
    final visibleRevealableTurns = revealableTurns
        .take(_visibleTurnCount.clamp(0, revealableTurns.length))
        .toList();
    final hasChoices = !isOutcomeMode &&
        currentTurn != null &&
        currentTurn.choices.isNotEmpty &&
        _visibleTurnCount >= revealableTurns.length &&
        !_isAwaitingTurnCompletion;
    final showOutcomeNext = isOutcomeMode &&
        _visibleTurnCount >= revealableTurns.length &&
        !_isAwaitingTurnCompletion;

    if (_showChoiceGuide && hasChoices) {
      _scheduleChoiceRectSync();
    }

    return Stack(
      children: [
        Column(
          children: [
            _SceneHeader(
              title: widget.scene.title,
              topic: widget.text.topicLabel(widget.scene.topic),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...visibleRevealableTurns,
                    if (hasChoices)
                      ...currentTurn.choices.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: ScenarioScreen._chatSpacing,
                              ),
                              child: _PlayerChoiceBubble(
                                key:
                                    entry.key == 0 ? _firstChoiceBubbleKey : null,
                                playerName: widget.scene.characters.player.name,
                                playerAvatarPath: playerAvatarPath,
                                text: entry.value.text,
                                color: playerColor,
                                onTap: () => widget.onPickChoice(entry.value.id),
                                showAvatar: entry.key == 0,
                              ),
                            ),
                          ),
                    if (showOutcomeNext)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: ScenarioScreen._chatSpacing,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: widget.onNextOutcome == null
                                ? null
                                : () {
                                    widget.onNextOutcome!.call();
                                  },
                            child: Text(widget.text.next),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_showChoiceGuide && hasChoices)
          Positioned.fill(
            child: _ChoiceGuideOverlay(
              spotlightRect: _choiceBubbleRect,
              onDismiss: _dismissChoiceGuide,
              message: widget.text.choiceGuideMessage,
            ),
          ),
      ],
    );
  }
}

class _ChoiceGuideOverlay extends StatefulWidget {
  const _ChoiceGuideOverlay({
    required this.spotlightRect,
    required this.onDismiss,
    required this.message,
  });

  final Rect? spotlightRect;
  final VoidCallback onDismiss;
  final String message;

  @override
  State<_ChoiceGuideOverlay> createState() => _ChoiceGuideOverlayState();
}

class _ChoiceGuideOverlayState extends State<_ChoiceGuideOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);
  late final Animation<double> _offset = Tween<double>(
    begin: 0,
    end: -6,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.9,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final rect = widget.spotlightRect;
    final panelTop = (() {
      if (rect == null) return size.height * 0.58;
      final preferred = rect.top - 116;
      if (preferred >= 72) return preferred;
      return (rect.bottom + 20).clamp(72.0, size.height - 180.0);
    })();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onDismiss,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SpotlightOverlayPainter(spotlightRect: rect),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: panelTop,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _offset.value),
                    child: child,
                  ),
                );
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.message,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightOverlayPainter extends CustomPainter {
  const _SpotlightOverlayPainter({required this.spotlightRect});

  final Rect? spotlightRect;

  @override
  void paint(Canvas canvas, Size size) {
    final canvasBounds = Offset.zero & size;
    canvas.saveLayer(canvasBounds, Paint());
    canvas.drawRect(
      canvasBounds,
      Paint()..color = const Color(0xB3000000),
    );

    if (spotlightRect != null) {
      final expanded = spotlightRect!.inflate(8);
      final holeRRect = RRect.fromRectAndRadius(expanded, const Radius.circular(16));
      canvas.drawRRect(
        holeRRect,
        Paint()..blendMode = ui.BlendMode.clear,
      );
    }

    canvas.restore();

    if (spotlightRect != null) {
      final borderRect = spotlightRect!.inflate(8);
      final border = RRect.fromRectAndRadius(borderRect, const Radius.circular(16));
      canvas.drawRRect(
        border,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightOverlayPainter oldDelegate) {
    return oldDelegate.spotlightRect != spotlightRect;
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
    return _AnimatedChatEntry(
      child: Padding(
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
              _TypingText(
                text,
                style: ScenarioScreen._conversationTextStyle(context),
              ),
            ],
          ),
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
    return _AnimatedChatEntry(
      child: Padding(
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
                child: _TypingText(
                  text,
                  style: ScenarioScreen._conversationTextStyle(context),
                ),
              ),
            ),
          ],
        ),
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
    return _AnimatedChatEntry(
      child: Padding(
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
                child: _TypingText(
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
      ),
    );
  }
}

class _PlayerChoiceBubble extends StatefulWidget {
  const _PlayerChoiceBubble({
    super.key,
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
  State<_PlayerChoiceBubble> createState() => _PlayerChoiceBubbleState();
}

class _PlayerChoiceBubbleState extends State<_PlayerChoiceBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 1.015,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  late final Animation<double> _glow = Tween<double>(
    begin: 0.08,
    end: 0.22,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scale.value,
                alignment: Alignment.centerRight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: _glow.value),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: child,
                ),
              );
            },
            child: OutlinedButton(
              onPressed: widget.onTap,
              style: OutlinedButton.styleFrom(
                backgroundColor: widget.color,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.text,
                textAlign: TextAlign.left,
                style: ScenarioScreen._conversationTextStyle(context),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 52,
          child: widget.showAvatar
              ? _Avatar(path: widget.playerAvatarPath, label: widget.playerName)
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
    return _AnimatedChatEntry(
      child: Padding(
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
              _TypingText(text),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedChatEntry extends StatefulWidget {
  const _AnimatedChatEntry({required this.child});

  static const Duration animationDuration = Duration(milliseconds: 240);

  final Widget child;

  @override
  State<_AnimatedChatEntry> createState() => _AnimatedChatEntryState();
}

class _AnimatedChatEntryState extends State<_AnimatedChatEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _AnimatedChatEntry.animationDuration,
  )..forward();
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

class _TypingText extends StatefulWidget {
  const _TypingText(
    this.text, {
    this.style,
    this.textAlign,
  });

  static Duration durationForText(String text) {
    return Duration(
      milliseconds: (text.characters.length * 18).clamp(180, 900),
    );
  }

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  State<_TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<_TypingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _TypingText.durationForText(widget.text),
  )..forward();
  late final Animation<int> _visibleCharacters = StepTween(
    begin: 0,
    end: widget.text.characters.length,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _visibleCharacters,
      builder: (context, _) {
        final visibleCount = _visibleCharacters.value;
        final visibleText = widget.text.characters.take(visibleCount).toString();
        return Text(
          visibleText,
          textAlign: widget.textAlign,
          style: widget.style,
        );
      },
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
    final isAsset = path.startsWith('assets/');
    return Column(
      children: [
        ClipOval(
          child: SizedBox(
            width: 40,
            height: 40,
            child: isAsset
                ? Image.asset(
                    path,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: Colors.grey.shade300,
                        alignment: Alignment.center,
                        child: const Icon(Icons.person, size: 20),
                      );
                    },
                  )
                : Image.file(
                    File(path),
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

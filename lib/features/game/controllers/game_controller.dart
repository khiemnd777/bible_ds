import 'package:bible_decision_simulator/features/monetization/rewarded_ad_service.dart';
import 'package:bible_decision_simulator/game_engine/content/content_store.dart';
import 'package:bible_decision_simulator/game_engine/content/content_validator.dart';
import 'package:bible_decision_simulator/game_engine/models/content_models.dart';
import 'package:bible_decision_simulator/game_engine/models/game_state.dart';
import 'package:bible_decision_simulator/game_engine/models/portrait_models.dart';
import 'package:bible_decision_simulator/game_engine/persistence/progress_store.dart';
import 'package:bible_decision_simulator/game_engine/rules/scheduler.dart';
import 'package:bible_decision_simulator/game_engine/runtime/game_engine.dart';
import 'package:bible_decision_simulator/game_engine/stat/stat_state.dart';
import 'package:bible_decision_simulator/game_engine/stat/daily_snapshot.dart';
import 'package:bible_decision_simulator/game_engine/stat/daily_trend_engine.dart';
import 'package:bible_decision_simulator/game_engine/runtime/portrait_resolver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameViewState {
  static const _unset = Object();

  final bool isLoading;
  final String? error;
  final GameContent? content;
  final Scene? scene;
  final ReflectionContent? reflection;
  final Choice? selectedChoice;
  final List<Choice> selectedChoices;
  final List<ConversationTurn> selectedTurns;
  final String? currentTurnId;
  final String? outcomeText;
  final String? outcomeNext;
  final StatState stats;
  final ProgressState progress;
  final GamePhase phase;
  final PortraitPair portraits;
  final List<String> validationErrors;
  final String endingSummary;
  final bool canNextDay;
  final DailyTrend? dailyTrend;

  const GameViewState({
    required this.isLoading,
    required this.error,
    required this.content,
    required this.scene,
    required this.reflection,
    required this.selectedChoice,
    required this.selectedChoices,
    required this.selectedTurns,
    required this.currentTurnId,
    required this.outcomeText,
    required this.outcomeNext,
    required this.stats,
    required this.progress,
    required this.phase,
    required this.portraits,
    required this.validationErrors,
    required this.endingSummary,
    required this.canNextDay,
    required this.dailyTrend,
  });

  factory GameViewState.initial() {
    return GameViewState(
      isLoading: true,
      error: null,
      content: null,
      scene: null,
      reflection: null,
      selectedChoice: null,
      selectedChoices: const [],
      selectedTurns: const [],
      currentTurnId: null,
      outcomeText: null,
      outcomeNext: null,
      stats: StatState.initial(),
      progress: ProgressState.initial(),
      phase: GamePhase.scenario,
      portraits: PortraitPair.empty(),
      validationErrors: const [],
      endingSummary: '',
      canNextDay: false,
      dailyTrend: null,
    );
  }

  GameViewState copyWith({
    bool? isLoading,
    Object? error = _unset,
    GameContent? content,
    Scene? scene,
    Object? reflection = _unset,
    Object? selectedChoice = _unset,
    List<Choice>? selectedChoices,
    List<ConversationTurn>? selectedTurns,
    Object? currentTurnId = _unset,
    Object? outcomeText = _unset,
    Object? outcomeNext = _unset,
    StatState? stats,
    ProgressState? progress,
    GamePhase? phase,
    PortraitPair? portraits,
    List<String>? validationErrors,
    String? endingSummary,
    bool? canNextDay,
    Object? dailyTrend = _unset,
  }) {
    return GameViewState(
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      content: content ?? this.content,
      scene: scene ?? this.scene,
      reflection: identical(reflection, _unset)
          ? this.reflection
          : reflection as ReflectionContent?,
      selectedChoice: identical(selectedChoice, _unset)
          ? this.selectedChoice
          : selectedChoice as Choice?,
      selectedChoices: selectedChoices ?? this.selectedChoices,
      selectedTurns: selectedTurns ?? this.selectedTurns,
      currentTurnId: identical(currentTurnId, _unset)
          ? this.currentTurnId
          : currentTurnId as String?,
      outcomeText: identical(outcomeText, _unset)
          ? this.outcomeText
          : outcomeText as String?,
      outcomeNext: identical(outcomeNext, _unset)
          ? this.outcomeNext
          : outcomeNext as String?,
      stats: stats ?? this.stats,
      progress: progress ?? this.progress,
      phase: phase ?? this.phase,
      portraits: portraits ?? this.portraits,
      validationErrors: validationErrors ?? this.validationErrors,
      endingSummary: endingSummary ?? this.endingSummary,
      canNextDay: canNextDay ?? this.canNextDay,
      dailyTrend: identical(dailyTrend, _unset)
          ? this.dailyTrend
          : dailyTrend as DailyTrend?,
    );
  }
}

class GameController extends StateNotifier<GameViewState> {
  GameController({
    required ContentStore contentStore,
    required ContentValidator validator,
    required Scheduler scheduler,
    required GameEngine gameEngine,
    required ProgressStore progressStore,
    required PortraitResolver portraitResolver,
    required RewardedAdService rewardedAdService,
    required String initialLocaleCode,
  })  : _contentStore = contentStore,
        _validator = validator,
        _scheduler = scheduler,
        _gameEngine = gameEngine,
        _progressStore = progressStore,
        _portraitResolver = portraitResolver,
        _dailyTrendEngine = const DailyTrendEngine(),
        _rewardedAdService = rewardedAdService,
        _localeCode = initialLocaleCode,
        super(GameViewState.initial()) {
    initialize();
  }

  final ContentStore _contentStore;
  final ContentValidator _validator;
  final Scheduler _scheduler;
  final GameEngine _gameEngine;
  final ProgressStore _progressStore;
  final PortraitResolver _portraitResolver;
  final DailyTrendEngine _dailyTrendEngine;
  final RewardedAdService _rewardedAdService;
  String _localeCode;

  Future<void> initialize() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final content = await _contentStore.load(localeCode: _localeCode);
      final validationErrors = _validator.validate(content);
      final stats = await _progressStore.loadStats();
      final dailySnapshot = await _progressStore.loadDailySnapshot();
      if (dailySnapshot == null) {
        await _progressStore.saveDailySnapshot(
          DailySnapshot(
            startDate: DateTime.now(),
            startStat: stats,
          ),
        );
      }
      var progress = await _progressStore.loadProgress();

      final assignment = _scheduler.assignSceneForDay(
        now: DateTime.now(),
        dayOffset: progress.dayOffset,
        scenes: content.scenes,
      );

      final needsNewAssignment = progress.currentDayKey != assignment.dayKey ||
          progress.assignedSceneId.isEmpty;

      if (needsNewAssignment) {
        progress = progress.copyWith(
          currentDayKey: assignment.dayKey,
          assignedSceneId: assignment.sceneId,
          completedToday: false,
        );
        await _progressStore.saveProgress(progress);
      }

      final scene = content.scenes
          .where((s) => s.id == progress.assignedSceneId)
          .cast<Scene?>()
          .firstWhere((s) => s != null,
              orElse: () =>
                  content.scenes.isNotEmpty ? content.scenes.first : null);

      final portraits = scene == null
          ? PortraitPair.empty()
          : _portraitResolver.resolveScenePortraits(scene);
      final canNextDay = _canAssignNextDayScene(
        content: content,
        dayOffset: progress.dayOffset,
      );

      state = state.copyWith(
        isLoading: false,
        content: content,
        scene: scene,
        reflection: null,
        selectedChoice: null,
        selectedChoices: const [],
        selectedTurns: const [],
        currentTurnId:
            scene?.firstTurnWithChoices(scene.conversation.startTurnId)?.id,
        outcomeText: null,
        outcomeNext: null,
        stats: stats,
        progress: progress,
        phase: GamePhase.scenario,
        portraits: portraits,
        validationErrors: validationErrors,
        endingSummary: _gameEngine.buildEndingSummary(stats),
        canNextDay: canNextDay,
        dailyTrend: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize: $e',
      );
    }
  }

  Future<void> chooseChoice(String choiceId) async {
    final scene = state.scene;
    if (scene == null) return;
    if (state.currentTurnId != null) {
      final turn = scene.findTurn(state.currentTurnId!);
      if (turn == null) return;

      Choice? choice;
      for (final c in turn.choices) {
        if (c.id == choiceId) {
          choice = c;
          break;
        }
      }
      if (choice == null) return;

      final nextStats = _gameEngine
          .resolveChoice(choice: choice, currentStats: state.stats)
          .nextStats;
      await _progressStore.saveStats(nextStats);

      final portraits = _portraitResolver.resolveScenePortraits(
        scene,
        intentTag: choice.intentTag,
        overrides: choice.portraitOverrides,
      );

      final nextSelectedChoices = [...state.selectedChoices, choice];
      final nextSelectedTurns = [...state.selectedTurns, turn];
      final nextChoiceIds = nextSelectedChoices.map((c) => c.id).toList();

      if (choice.nextTurnId.isNotEmpty) {
        final nextTurn = scene.firstTurnWithChoices(choice.nextTurnId);
        if (nextTurn != null) {
          state = state.copyWith(
            selectedChoice: choice,
            selectedChoices: nextSelectedChoices,
            selectedTurns: nextSelectedTurns,
            currentTurnId: nextTurn.id,
            outcomeText: null,
            outcomeNext: null,
            stats: nextStats,
            phase: GamePhase.scenario,
            portraits: portraits,
            endingSummary: _gameEngine.buildEndingSummary(nextStats),
          );
          return;
        }
      }

      final resolution = _gameEngine.resolveConversationOutcome(
        scene: scene,
        selectedChoiceIds: nextChoiceIds,
        currentStats: nextStats,
        fallbackChoice: choice,
      );

      state = state.copyWith(
        selectedChoice: choice,
        selectedChoices: nextSelectedChoices,
        selectedTurns: nextSelectedTurns,
        currentTurnId: null,
        outcomeText: resolution.outcomeText,
        outcomeNext: resolution.nextTag,
        stats: resolution.nextStats,
        phase: GamePhase.outcome,
        portraits: portraits,
        endingSummary: _gameEngine.buildEndingSummary(resolution.nextStats),
      );
      return;
    }
  }

  void goToReflection() {
    final scene = state.scene;
    final content = state.content;
    if (scene == null || content == null) return;

    final reflection = _gameEngine.pickReflection(
      scene: scene,
      content: content,
      nextTag: state.outcomeNext,
    );

    state = state.copyWith(
      reflection: reflection,
      phase: GamePhase.reflection,
    );
  }

  Future<void> goToSummary() async {
    final progress = state.progress;
    final todayKey = _scheduler.dayKey(
      DateTime.now().add(Duration(days: progress.dayOffset)),
    );

    final nextStreak = progress.completedToday
        ? progress.streak
        : _scheduler.computeStreak(
            progress.lastPlayedDayKey, todayKey, progress.streak);

    final nextProgress = progress.copyWith(
      completedToday: true,
      lastPlayedDayKey: todayKey,
      streak: nextStreak,
    );
    await _progressStore.saveProgress(nextProgress);

    final currentStats = state.stats;
    var dailySnapshot = await _progressStore.loadDailySnapshot();
    dailySnapshot ??= DailySnapshot(
      startDate: DateTime.now(),
      startStat: currentStats,
    );
    await _progressStore.saveDailySnapshot(dailySnapshot);

    final shouldShowDailySummary =
        DateTime.now().difference(dailySnapshot.startDate).inDays >= 1;
    DailyTrend? dailyTrend;
    var phase = GamePhase.summary;
    if (shouldShowDailySummary) {
      dailyTrend = _dailyTrendEngine.calculateTrend(
        dailySnapshot.startStat,
        currentStats,
      );
      phase = GamePhase.dailySummary;
      await _progressStore.saveDailySnapshot(
        DailySnapshot(
          startDate: DateTime.now(),
          startStat: currentStats,
        ),
      );
    }

    state = state.copyWith(
      progress: nextProgress,
      phase: phase,
      dailyTrend: dailyTrend,
    );
  }

  Future<void> nextDay() async {
    if (!state.canNextDay) return;
    final nextProgress = state.progress.copyWith(
      dayOffset: state.progress.dayOffset + 1,
      completedToday: false,
      assignedSceneId: '',
      currentDayKey: '',
    );
    await _progressStore.saveProgress(nextProgress);
    state = state.copyWith(progress: nextProgress);
    await initialize();
  }

  Future<void> goToday() async {
    final todayProgress = state.progress.copyWith(
      dayOffset: 0,
      completedToday: false,
      assignedSceneId: '',
      currentDayKey: '',
    );
    await _progressStore.saveProgress(todayProgress);
    state = state.copyWith(progress: todayProgress);
    await initialize();
  }

  Future<void> watchRewardedAd() async {
    await _rewardedAdService.loadRewardedAd();
    await _rewardedAdService.showRewardedAd(onRewardEarned: () {});
  }

  Future<void> setLocale(String localeCode) async {
    if (_localeCode == localeCode) return;
    _localeCode = localeCode;
    await initialize();
  }

  bool _canAssignNextDayScene({
    required GameContent content,
    required int dayOffset,
  }) {
    if (content.scenes.isEmpty) return false;
    final nextAssignment = _scheduler.assignSceneForDay(
      now: DateTime.now(),
      dayOffset: dayOffset + 1,
      scenes: content.scenes,
    );
    if (nextAssignment.sceneId.isEmpty) return false;
    return content.scenes.any((scene) => scene.id == nextAssignment.sceneId);
  }
}

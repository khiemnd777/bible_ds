import 'package:bible_decision_simulator/game_engine/content/content_store.dart';
import 'package:bible_decision_simulator/game_engine/content/content_validator.dart';
import 'package:bible_decision_simulator/game_engine/models/content_models.dart';
import 'package:bible_decision_simulator/game_engine/runtime/game_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContentPreviewState {
  final bool isLoading;
  final String? error;
  final GameContent? content;
  final Scene? selectedScene;
  final Choice? selectedChoice;
  final String? simulatedOutcome;
  final ReflectionContent? simulatedReflection;
  final List<String> validationErrors;

  const ContentPreviewState({
    required this.isLoading,
    required this.error,
    required this.content,
    required this.selectedScene,
    required this.selectedChoice,
    required this.simulatedOutcome,
    required this.simulatedReflection,
    required this.validationErrors,
  });

  factory ContentPreviewState.initial() {
    return const ContentPreviewState(
      isLoading: true,
      error: null,
      content: null,
      selectedScene: null,
      selectedChoice: null,
      simulatedOutcome: null,
      simulatedReflection: null,
      validationErrors: [],
    );
  }

  ContentPreviewState copyWith({
    bool? isLoading,
    String? error,
    GameContent? content,
    Scene? selectedScene,
    Choice? selectedChoice,
    String? simulatedOutcome,
    ReflectionContent? simulatedReflection,
    List<String>? validationErrors,
  }) {
    return ContentPreviewState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      content: content ?? this.content,
      selectedScene: selectedScene ?? this.selectedScene,
      selectedChoice: selectedChoice ?? this.selectedChoice,
      simulatedOutcome: simulatedOutcome ?? this.simulatedOutcome,
      simulatedReflection: simulatedReflection ?? this.simulatedReflection,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }
}

class ContentPreviewController extends StateNotifier<ContentPreviewState> {
  ContentPreviewController({
    required ContentStore contentStore,
    required ContentValidator validator,
    required GameEngine gameEngine,
    required String initialLocaleCode,
  })  : _contentStore = contentStore,
        _validator = validator,
        _gameEngine = gameEngine,
        _localeCode = initialLocaleCode,
        super(ContentPreviewState.initial()) {
    initialize();
  }

  final ContentStore _contentStore;
  final ContentValidator _validator;
  final GameEngine _gameEngine;
  String _localeCode;

  Future<void> initialize() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final content = await _contentStore.load(localeCode: _localeCode);
      final errors = _validator.validate(content);
      final initialScene = content.scenes.isEmpty ? null : content.scenes.first;

      state = state.copyWith(
        isLoading: false,
        content: content,
        selectedScene: initialScene,
        selectedChoice: null,
        simulatedOutcome: null,
        simulatedReflection: null,
        validationErrors: errors,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load preview: $e',
      );
    }
  }

  void selectScene(String sceneId) {
    final content = state.content;
    if (content == null) return;

    Scene? scene;
    for (final s in content.scenes) {
      if (s.id == sceneId) {
        scene = s;
        break;
      }
    }

    state = state.copyWith(
      selectedScene: scene,
      selectedChoice: null,
      simulatedOutcome: null,
      simulatedReflection: null,
    );
  }

  void simulateChoice(String choiceId) {
    final content = state.content;
    final scene = state.selectedScene;
    if (content == null || scene == null) return;

    Choice? choice;
    for (final c in scene.initialChoices) {
      if (c.id == choiceId) {
        choice = c;
        break;
      }
    }
    if (choice == null) return;

    final reflection = _gameEngine.pickReflection(
      scene: scene,
      content: content,
      nextTag: choice.outcome.next,
    );

    state = state.copyWith(
      selectedChoice: choice,
      simulatedOutcome: choice.outcome.text,
      simulatedReflection: reflection,
    );
  }

  Future<void> setLocale(String localeCode) async {
    if (_localeCode == localeCode) return;
    _localeCode = localeCode;
    await initialize();
  }
}

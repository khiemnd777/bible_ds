import 'dart:ui' as ui;

import 'package:bible_decision_simulator/core/i18n_catalog.dart';
import 'package:bible_decision_simulator/core/i18n.dart';
import 'package:bible_decision_simulator/features/game/controllers/game_controller.dart';
import 'package:bible_decision_simulator/features/preview/content_preview_controller.dart';
import 'package:bible_decision_simulator/game_engine/content/content_loader.dart';
import 'package:bible_decision_simulator/game_engine/content/content_store.dart';
import 'package:bible_decision_simulator/game_engine/content/content_validator.dart';
import 'package:bible_decision_simulator/game_engine/persistence/progress_store.dart';
import 'package:bible_decision_simulator/game_engine/persistence/sp_progress_store.dart';
import 'package:bible_decision_simulator/game_engine/rules/ending_engine.dart';
import 'package:bible_decision_simulator/game_engine/rules/scheduler.dart';
import 'package:bible_decision_simulator/game_engine/runtime/daily_scheduler.dart';
import 'package:bible_decision_simulator/game_engine/rules/stat_engine.dart';
import 'package:bible_decision_simulator/game_engine/runtime/game_engine.dart';
import 'package:bible_decision_simulator/game_engine/runtime/portrait_resolver.dart';
import 'package:bible_decision_simulator/game_engine/runtime/streak_service.dart';
import 'package:bible_decision_simulator/features/monetization/rewarded_ad_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main()'),
);

final i18nCatalogProvider = Provider<I18nCatalog>(
  (ref) => throw UnimplementedError('Override in main()'),
);

class AppLocaleController extends StateNotifier<String> {
  AppLocaleController(this._prefs) : super(_initialLocale(_prefs));

  static const String prefsKey = 'bds.locale';
  final SharedPreferences _prefs;

  Future<void> setLocale(String localeCode) async {
    if (state == localeCode) return;
    state = localeCode;
    await _prefs.setString(prefsKey, localeCode);
  }

  static String _initialLocale(SharedPreferences prefs) {
    final saved = prefs.getString(prefsKey);
    if (saved != null && saved.isNotEmpty) return saved;

    final locale = ui.PlatformDispatcher.instance.locale;
    if (locale.languageCode == 'vi') return 'vi_VN';
    return 'en_US';
  }
}

final appLocaleProvider = StateNotifierProvider<AppLocaleController, String>(
  (ref) => AppLocaleController(ref.read(sharedPreferencesProvider)),
);

final uiTextProvider = Provider<UiText>((ref) {
  final localeCode = ref.watch(appLocaleProvider);
  final catalog = ref.watch(i18nCatalogProvider);
  return UiText.fromLocaleCode(localeCode, catalog);
});

final contentLoaderProvider = Provider<ContentLoader>((ref) {
  return const ContentLoader();
});

final contentStoreProvider = Provider<ContentStore>((ref) {
  return ContentStore(ref.read(contentLoaderProvider));
});

final contentValidatorProvider = Provider<ContentValidator>((ref) {
  return const ContentValidator();
});

final statEngineProvider = Provider<StatEngine>((ref) {
  return const StatEngine();
});

final endingEngineProvider = Provider<EndingEngine>((ref) {
  return const EndingEngine();
});

final schedulerProvider = Provider<Scheduler>((ref) {
  return const Scheduler();
});

final dailySchedulerProvider = Provider<DailyScheduler>((ref) {
  return const DailyScheduler();
});

final streakServiceProvider = Provider<StreakService>((ref) {
  return const StreakService();
});

final portraitResolverProvider = Provider<PortraitResolver>((ref) {
  return const PortraitResolver();
});

final gameEngineProvider = Provider<GameEngine>((ref) {
  return GameEngine(
    statEngine: ref.read(statEngineProvider),
    endingEngine: ref.read(endingEngineProvider),
  );
});

final progressStoreProvider = Provider<ProgressStore>((ref) {
  return SpProgressStore(ref.read(sharedPreferencesProvider));
});

final rewardedAdServiceProvider = Provider<RewardedAdService>((ref) {
  return RewardedAdService();
});

final gameControllerProvider =
    StateNotifierProvider<GameController, GameViewState>((ref) {
  final controller = GameController(
    contentStore: ref.read(contentStoreProvider),
    validator: ref.read(contentValidatorProvider),
    scheduler: ref.read(schedulerProvider),
    dailyScheduler: ref.read(dailySchedulerProvider),
    streakService: ref.read(streakServiceProvider),
    gameEngine: ref.read(gameEngineProvider),
    progressStore: ref.read(progressStoreProvider),
    portraitResolver: ref.read(portraitResolverProvider),
    rewardedAdService: ref.read(rewardedAdServiceProvider),
    initialLocaleCode: ref.read(appLocaleProvider),
  );

  ref.listen<String>(appLocaleProvider, (previous, next) {
    controller.setLocale(next);
  });

  return controller;
});

final contentPreviewControllerProvider =
    StateNotifierProvider<ContentPreviewController, ContentPreviewState>((ref) {
  final controller = ContentPreviewController(
    contentStore: ref.read(contentStoreProvider),
    validator: ref.read(contentValidatorProvider),
    gameEngine: ref.read(gameEngineProvider),
    initialLocaleCode: ref.read(appLocaleProvider),
  );

  ref.listen<String>(appLocaleProvider, (previous, next) {
    controller.setLocale(next);
  });

  return controller;
});

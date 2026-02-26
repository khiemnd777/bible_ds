import 'package:bible_decision_simulator/core/i18n_catalog.dart';
import 'package:bible_decision_simulator/game_engine/models/game_state.dart';

class UiText {
  UiText._(this.localeCode, this.catalog);

  final String localeCode;
  final I18nCatalog catalog;

  static UiText fromLocaleCode(String localeCode, I18nCatalog catalog) {
    return UiText._(localeCode, catalog);
  }

  String _t(String key, String fallback) {
    return catalog.lookup(localeCode, key) ?? fallback;
  }

  String get appTitle => _t('app_title', 'Bible Decision Simulator');
  String get playTab => _t('play_tab', 'Play');
  String get previewTab => _t('preview_tab', 'Preview');
  String get noSceneAvailable =>
      _t('no_scene_available', 'No scene available.');
  String get next => _t('next', 'Next');
  String get reflection => _t('reflection', 'Reflection');
  String get noReflectionAvailable =>
      _t('no_reflection_available', 'No reflection available.');
  String get questions => _t('questions', 'Questions');
  String get continueText => _t('continue', 'Continue');
  String get daySummary => _t('day_summary', 'Day Summary');
  String get currentStreak => _t('current_streak', 'Current Streak');
  String get summaryMenu => _t('summary_menu', 'Summary');
  String dayCount(int n) =>
      _t('day_count_template', '{n} day(s)').replaceAll('{n}', '$n');
  String statLabel(GameStat stat) => switch (stat) {
        GameStat.faith => _t('stat_faith', 'faith'),
        GameStat.love => _t('stat_love', 'love'),
        GameStat.obedience => _t('stat_obedience', 'obedience'),
        GameStat.humility => _t('stat_humility', 'humility'),
        GameStat.wisdom => _t('stat_wisdom', 'wisdom'),
        GameStat.fear => _t('stat_fear', 'fear'),
        GameStat.pride => _t('stat_pride', 'pride'),
      };
  String get nextDay => _t('next_day', 'Next Day');
  String get today => _t('today', 'Today');
  String get donate => _t('donate', 'Donate');

  String get contentPreview => _t('content_preview', 'Content Preview');
  String get scene => _t('scene', 'Scene');
  String get simulateChoice => _t('simulate_choice', 'Simulate Choice');
  String get outcome => _t('outcome', 'Outcome');
  String get validation => _t('validation', 'Validation');
  String get noValidationErrors =>
      _t('no_validation_errors', 'No validation errors.');
  String get noContentLoaded => _t('no_content_loaded', 'No content loaded.');
}

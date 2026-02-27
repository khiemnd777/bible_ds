import 'package:bible_decision_simulator/core/i18n_catalog.dart';

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
  String get profileTab => _t('profile_tab', 'Profile');
  String get noSceneAvailable =>
      _t('no_scene_available', 'No scene available.');
  String get next => _t('next', 'Next');
  String get reflection => _t('reflection', 'Reflection');
  String get noReflectionAvailable =>
      _t('no_reflection_available', 'No reflection available.');
  String get questions => _t('questions', 'Questions');
  String get continueText => _t('continue', 'Continue');
  String get submit => _t('submit', 'Submit');
  String get ok => _t('ok', 'OK');
  String get profileSavedSuccess =>
      _t('profile_saved_success', 'Profile saved successfully.');
  String get daySummary => _t('day_summary', 'Day Summary');
  String get currentStreak => _t('current_streak', 'Current Streak');
  String get summaryMenu => _t('summary_menu', 'Summary');
  String dayCount(int n) =>
      _t('day_count_template', '{n} day(s)').replaceAll('{n}', '$n');
  String statLabel(String statKey) => switch (statKey) {
        'faith' => _t('stat_faith', 'faith'),
        'love' => _t('stat_love', 'love'),
        'humility' => _t('stat_humility', 'humility'),
        'wisdom' => _t('stat_wisdom', 'wisdom'),
        'pride' => _t('stat_pride', 'pride'),
        _ => statKey,
      };
  String get dailyTrend => _t('daily_trend', 'Daily Spiritual Trend');
  String get nextDay => _t('next_day', 'Next Day');
  String get situation => _t('situation', 'Situation');
  String get selectSituation => _t('select_situation', 'Select a situation');
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
  String get generateProfileTitle =>
      _t('generate_profile_title', 'Generate Profile');
  String get yourNameLabel => _t('your_name_label', 'Your name');
  String get yourAvatarLabel => _t('your_avatar_label', 'Your avatar');
  String get uploadAvatarButton => _t('upload_avatar_button', 'Upload avatar');
  String get chooseAvatarSourceTitle =>
      _t('choose_avatar_source_title', 'Choose avatar source');
  String get galleryOption => _t('gallery_option', 'Gallery');
  String get cancel => _t('cancel', 'Cancel');
  String get avatarScaleLabel => _t('avatar_scale_label', 'Avatar scale');
  String get yourEmailOptionalLabel =>
      _t('your_email_optional_label', 'Your email (optional)');
  String get yourPhoneOptionalLabel =>
      _t('your_phone_optional_label', 'Your phone (optional)');
}

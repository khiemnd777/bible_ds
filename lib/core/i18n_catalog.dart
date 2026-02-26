import 'dart:convert';

import 'package:flutter/services.dart';

class I18nCatalog {
  I18nCatalog(this._entriesByLocale);

  final Map<String, Map<String, String>> _entriesByLocale;

  static Future<I18nCatalog> loadFromAssets() async {
    final en = await _loadLocaleFile('assets/i18n/en_us.json');
    final vi = await _loadLocaleFile('assets/i18n/vi_vn.json');
    return I18nCatalog({
      'en_US': en,
      'vi_VN': vi,
    });
  }

  String? lookup(String localeCode, String key) {
    final normalized = _normalizeLocale(localeCode);
    final localized = _entriesByLocale[normalized];
    if (localized != null && localized.containsKey(key)) {
      return localized[key];
    }
    return _entriesByLocale['en_US']?[key];
  }

  static String _normalizeLocale(String localeCode) {
    if (localeCode == 'vi_VN' || localeCode.startsWith('vi')) return 'vi_VN';
    return 'en_US';
  }

  static Future<Map<String, String>> _loadLocaleFile(String path) async {
    final raw = await rootBundle.loadString(path);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((key, value) => MapEntry(key, value.toString()));
  }
}

import 'dart:convert';

import 'package:bible_decision_simulator/game_engine/models/content_models.dart';
import 'package:flutter/services.dart';

class ContentLoader {
  const ContentLoader();

  static const String defaultAssetPath = 'assets/content/scenes.json';
  static const String englishAssetPath = 'assets/content/scene_en.json';
  static const String vietnameseAssetPath = 'assets/content/scenes_vi.json';
  static const String _contentAssetDir = 'assets/content/';
  static final RegExp _versionedScenePattern = RegExp(
    r'^assets/content/scenes_v(\d+)_([a-z]{2}(?:_[a-z]{2})?)\.json$',
    caseSensitive: false,
  );
  static final RegExp _localeScenePattern = RegExp(
    r'^assets/content/scenes_([a-z]{2}(?:_[a-z]{2})?)\.json$',
    caseSensitive: false,
  );
  static final RegExp _simpleLocalePattern = RegExp(
    r'^[a-z]{2}(?:_[a-z]{2})?$',
    caseSensitive: false,
  );

  Future<GameContent> loadContent({
    String? localeCode,
    String? assetPath,
  }) async {
    final discovered = await _discoverSceneAssets();
    final candidates = <String>[
      if (assetPath != null && assetPath.isNotEmpty) assetPath,
      ..._localeAssetCandidates(localeCode, discovered),
      defaultAssetPath,
    ];

    for (final path in candidates.toSet()) {
      try {
        final raw = await rootBundle.loadString(path);
        final data = jsonDecode(raw) as Map<String, dynamic>;
        return GameContent.fromJson(data);
      } catch (_) {
        continue;
      }
    }

    throw const FormatException('Unable to load localized scenes content.');
  }

  Future<List<String>> _discoverSceneAssets() async {
    try {
      final raw = await rootBundle.loadString('AssetManifest.json');
      final manifest = jsonDecode(raw) as Map<String, dynamic>;
      return manifest.keys
          .where((asset) => asset.startsWith(_contentAssetDir))
          .where((asset) => asset.endsWith('.json'))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  List<String> _localeAssetCandidates(
    String? localeCode,
    List<String> availableAssets,
  ) {
    final locale = _normalizeLocale(localeCode);
    final fallbackLocales = locale == 'vi'
        ? const ['vi', 'en']
        : locale == 'en'
            ? const ['en']
            : const ['en'];

    final candidates = <String>[];
    for (final code in fallbackLocales) {
      final versioned = _bestVersionedAsset(availableAssets, code);
      if (versioned != null) candidates.add(versioned);

      final localized = _bestLocalizedAsset(availableAssets, code);
      if (localized != null) candidates.add(localized);
    }

    if (locale == 'vi') {
      candidates.add(vietnameseAssetPath);
      candidates.add(englishAssetPath);
    } else {
      candidates.add(englishAssetPath);
    }
    return candidates;
  }

  String? _bestVersionedAsset(List<String> assets, String localeCode) {
    String? bestPath;
    int bestVersion = -1;

    for (final asset in assets) {
      final match = _versionedScenePattern.firstMatch(asset);
      if (match == null) continue;

      final version = int.tryParse(match.group(1) ?? '') ?? -1;
      final fileLocale = _normalizeLocale(match.group(2));
      if (fileLocale != localeCode || version < 0) continue;

      if (version > bestVersion) {
        bestVersion = version;
        bestPath = asset;
      }
    }
    return bestPath;
  }

  String? _bestLocalizedAsset(List<String> assets, String localeCode) {
    for (final asset in assets) {
      final match = _localeScenePattern.firstMatch(asset);
      if (match == null) continue;
      if (_normalizeLocale(match.group(1)) == localeCode) return asset;
    }
    return null;
  }

  String _normalizeLocale(String? localeCode) {
    final normalized =
        (localeCode ?? '').trim().toLowerCase().replaceAll('-', '_');
    if (normalized.isEmpty) return 'en';

    if (_simpleLocalePattern.hasMatch(normalized)) {
      final parts = normalized.split('_');
      return parts.first;
    }

    if (normalized.startsWith('vi')) return 'vi';
    if (normalized.startsWith('en')) return 'en';
    return 'en';
  }
}

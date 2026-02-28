import 'dart:convert';

import 'package:bible_decision_simulator/game_engine/models/content_models.dart';
import 'package:flutter/services.dart';

class ContentLoader {
  const ContentLoader();

  static const String defaultAssetPath = 'assets/content/scenes.json';
  static const String englishAssetPath = 'assets/content/scene_en.json';
  static const String vietnameseAssetPath = 'assets/content/scenes_vi.json';
  static const String _contentAssetDir = 'assets/content/';
  static final RegExp _topicDualVersionedScenePattern = RegExp(
    r'^assets/content/scenes_v(\d+)_([a-z0-9_]+)_v(\d+)_([a-z]{2}(?:_[a-z]{2})?)\.json$',
    caseSensitive: false,
  );
  static final RegExp _topicVersionedScenePattern = RegExp(
    r'^assets/content/scenes_([a-z0-9_]+)_v(\d+)_([a-z]{2}(?:_[a-z]{2})?)\.json$',
    caseSensitive: false,
  );
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

    if (assetPath == null || assetPath.isEmpty) {
      final topicAssets = _selectTopicVersionedAssets(
        availableAssets: discovered,
        localeCode: _normalizeLocale(localeCode),
      );
      final orderedMergePaths = [
        ...candidates,
        ...topicAssets,
      ];
      final merged = await _loadAndMergeContents(orderedMergePaths);
      if (merged != null) return merged;
    }

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

  Future<GameContent?> _loadAndMergeContents(List<String> paths) async {
    final mergedScenes = <Scene>[];
    final mergedReflections = <ReflectionContent>[];

    for (final path in paths) {
      try {
        final raw = await rootBundle.loadString(path);
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final content = GameContent.fromJson(data);
        mergedScenes.addAll(content.scenes);
        mergedReflections.addAll(content.reflections);
      } catch (_) {
        continue;
      }
    }

    if (mergedScenes.isEmpty && mergedReflections.isEmpty) return null;
    return GameContent(scenes: mergedScenes, reflections: mergedReflections);
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

  List<String> _selectTopicVersionedAssets({
    required List<String> availableAssets,
    required String localeCode,
  }) {
    final preferredLocales = localeCode == 'vi'
        ? const ['vi', 'en']
        : localeCode == 'en'
            ? const ['en']
            : const ['en'];
    final ordered = <String>[];
    for (final locale in preferredLocales) {
      ordered.addAll(
        _selectDualVersionTopicAssetsForLocale(
          availableAssets: availableAssets,
          localeCode: locale,
        ),
      );
    }
    if (ordered.isNotEmpty) return ordered;

    // Backward-compatible fallback: load all scenes_{topic}_v{n}_{locale}.json
    final legacyCandidates = <_LegacyTopicAssetCandidate>[];

    for (final locale in preferredLocales) {
      for (final asset in availableAssets) {
        final match = _topicVersionedScenePattern.firstMatch(asset);
        if (match == null) continue;

        final topic = (match.group(1) ?? '').toLowerCase();
        final topicVersion = int.tryParse(match.group(2) ?? '') ?? -1;
        final fileLocale = _normalizeLocale(match.group(3));
        if (topic.isEmpty || topicVersion < 0 || fileLocale != locale) continue;
        legacyCandidates.add(
          _LegacyTopicAssetCandidate(
            path: asset,
            topic: topic,
            topicVersion: topicVersion,
          ),
        );
      }
    }

    legacyCandidates.sort((a, b) {
      final byTopic = a.topic.compareTo(b.topic);
      if (byTopic != 0) return byTopic;
      return a.topicVersion.compareTo(b.topicVersion);
    });

    return [
      for (final candidate in legacyCandidates) candidate.path,
    ];
  }

  List<String> _selectDualVersionTopicAssetsForLocale({
    required List<String> availableAssets,
    required String localeCode,
  }) {
    final parsed = <_TopicAssetCandidate>[];
    for (final asset in availableAssets) {
      final match = _topicDualVersionedScenePattern.firstMatch(asset);
      if (match == null) continue;

      final bundleVersion = int.tryParse(match.group(1) ?? '') ?? -1;
      final topic = (match.group(2) ?? '').toLowerCase();
      final topicVersion = int.tryParse(match.group(3) ?? '') ?? -1;
      final fileLocale = _normalizeLocale(match.group(4));
      if (bundleVersion < 0 ||
          topicVersion < 0 ||
          topic.isEmpty ||
          fileLocale != localeCode) {
        continue;
      }

      parsed.add(
        _TopicAssetCandidate(
          path: asset,
          bundleVersion: bundleVersion,
          topic: topic,
          topicVersion: topicVersion,
        ),
      );
    }

    if (parsed.isEmpty) return const [];

    parsed.sort((a, b) {
      final byBundle = a.bundleVersion.compareTo(b.bundleVersion);
      if (byBundle != 0) return byBundle;
      final byTopic = a.topic.compareTo(b.topic);
      if (byTopic != 0) return byTopic;
      return a.topicVersion.compareTo(b.topicVersion);
    });

    return [for (final candidate in parsed) candidate.path];
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

class _TopicAssetCandidate {
  const _TopicAssetCandidate({
    required this.path,
    required this.bundleVersion,
    required this.topic,
    required this.topicVersion,
  });

  final String path;
  final int bundleVersion;
  final String topic;
  final int topicVersion;
}

class _LegacyTopicAssetCandidate {
  const _LegacyTopicAssetCandidate({
    required this.path,
    required this.topic,
    required this.topicVersion,
  });

  final String path;
  final String topic;
  final int topicVersion;
}

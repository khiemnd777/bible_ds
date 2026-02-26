import 'dart:convert';

import 'package:bible_decision_simulator/game_engine/models/content_models.dart';
import 'package:flutter/services.dart';

class ContentLoader {
  const ContentLoader();

  static const String defaultAssetPath = 'assets/content/scenes.json';
  static const String englishAssetPath = 'assets/content/scene_en.json';
  static const String vietnameseAssetPath = 'assets/content/scenes_vi.json';

  Future<GameContent> loadContent({
    String? localeCode,
    String? assetPath,
  }) async {
    final candidates = <String>[
      if (assetPath != null && assetPath.isNotEmpty) assetPath,
      ..._localeAssetCandidates(localeCode),
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

  List<String> _localeAssetCandidates(String? localeCode) {
    final normalized = (localeCode ?? '').trim();
    if (normalized.isEmpty) {
      return const [englishAssetPath];
    }

    if (normalized == 'vi_VN' || normalized.startsWith('vi')) {
      return const [vietnameseAssetPath, englishAssetPath];
    }

    if (normalized == 'en_US' || normalized.startsWith('en')) {
      return const [englishAssetPath];
    }

    return const [englishAssetPath];
  }
}

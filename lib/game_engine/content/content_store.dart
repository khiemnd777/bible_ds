import 'package:bible_decision_simulator/game_engine/content/content_loader.dart';
import 'package:bible_decision_simulator/game_engine/models/content_models.dart';

class ContentStore {
  ContentStore(this._loader);

  final ContentLoader _loader;
  final Map<String, GameContent> _cacheByLocale = {};
  String _activeLocaleCode = 'en_US';

  Future<GameContent> load({String localeCode = 'en_US'}) async {
    _activeLocaleCode = localeCode;
    final cached = _cacheByLocale[localeCode];
    if (cached != null) return cached;

    final loaded = await _loader.loadContent(localeCode: localeCode);
    _cacheByLocale[localeCode] = loaded;
    return loaded;
  }

  Scene? sceneById(String id) {
    final content = _activeContent;
    if (content == null) return null;
    for (final scene in content.scenes) {
      if (scene.id == id) return scene;
    }
    return null;
  }

  ReflectionContent? reflectionById(String id) {
    final content = _activeContent;
    if (content == null) return null;
    for (final reflection in content.reflections) {
      if (reflection.id == id) return reflection;
    }
    return null;
  }

  List<String> topics() {
    final content = _activeContent;
    if (content == null) return [];
    final unique = <String>{};
    for (final scene in content.scenes) {
      unique.add(scene.topic);
    }
    return unique.toList()..sort();
  }

  GameContent? get _activeContent {
    return _cacheByLocale[_activeLocaleCode] ??
        (_cacheByLocale.isNotEmpty ? _cacheByLocale.values.first : null);
  }
}

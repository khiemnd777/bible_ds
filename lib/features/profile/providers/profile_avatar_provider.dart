import 'dart:io';

import 'package:bible_decision_simulator/core/di.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

const profileAvatarPathPrefsKey = 'bds.profile.avatar_path';

final profileAvatarPathProvider = FutureProvider<String?>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  final savedRef = prefs.getString(profileAvatarPathPrefsKey);
  if (savedRef == null || savedRef.isEmpty) return null;

  final docsDir = await getApplicationDocumentsDirectory();

  // Backward compatibility: old data may store absolute paths.
  if (savedRef.contains('/')) {
    final legacyFile = File(savedRef);
    if (legacyFile.existsSync()) return savedRef;

    final slash = savedRef.lastIndexOf('/');
    final migratedName = (slash < 0 || slash == savedRef.length - 1)
        ? savedRef
        : savedRef.substring(slash + 1);
    final migratedPath = '${docsDir.path}/$migratedName';
    if (File(migratedPath).existsSync()) return migratedPath;
    return null;
  }

  final currentPath = '${docsDir.path}/$savedRef';
  if (File(currentPath).existsSync()) return currentPath;
  return null;
});

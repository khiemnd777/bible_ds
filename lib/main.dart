import 'package:bible_decision_simulator/features/game/screens/scenario_screen.dart';
import 'package:bible_decision_simulator/features/game/screens/summary_screen.dart';
import 'package:bible_decision_simulator/features/preview/content_preview_screen.dart';
import 'package:bible_decision_simulator/features/profile/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/di.dart';
import 'core/i18n_catalog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final prefs = await SharedPreferences.getInstance();
  final i18nCatalog = await I18nCatalog.loadFromAssets();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        i18nCatalogProvider.overrideWithValue(i18nCatalog),
      ],
      child: const BibleDecisionSimulatorApp(),
    ),
  );
}

class BibleDecisionSimulatorApp extends ConsumerWidget {
  const BibleDecisionSimulatorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(uiTextProvider);
    return MaterialApp(
      title: text.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const _RootShell(),
    );
  }
}

class _RootShell extends ConsumerStatefulWidget {
  const _RootShell();

  @override
  ConsumerState<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<_RootShell> {
  int _index = 2;

  @override
  Widget build(BuildContext context) {
    final localeCode = ref.watch(appLocaleProvider);
    final text = ref.watch(uiTextProvider);
    final gameState = ref.watch(gameControllerProvider);
    final gameController = ref.read(gameControllerProvider.notifier);

    final pages = [
      const GameFlowScreen(),
      const ContentPreviewScreen(),
      SummaryScreen(
        stats: gameState.stats,
        streak: gameState.progress.streak,
        endingSummary: gameState.endingSummary,
        scenes: gameState.content?.scenes ?? const [],
        currentSceneId: gameState.scene?.id,
        onOpenSceneByIndex: gameController.openSceneByIndex,
        onNavigateScenarioView: () => setState(() => _index = 0),
        text: text,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(text.appTitle),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: localeCode == 'vi_VN' ? 'vi_VN' : 'en_US',
                  items: const [
                    DropdownMenuItem(
                      value: 'en_US',
                      child: Text('English'),
                    ),
                    DropdownMenuItem(
                      value: 'vi_VN',
                      child: Text('Tiếng Việt'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    ref.read(appLocaleProvider.notifier).setLocale(value);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: text.playTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.preview_outlined),
            selectedIcon: Icon(Icons.preview),
            label: text.previewTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: text.summaryMenu,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: text.profileTab,
          ),
        ],
      ),
    );
  }
}

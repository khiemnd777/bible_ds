import 'package:bible_decision_simulator/core/di.dart';
import 'package:bible_decision_simulator/core/i18n.dart';
import 'package:bible_decision_simulator/features/monetization/donate_dialog.dart';
import 'package:bible_decision_simulator/game_engine/models/content_models.dart';
import 'package:bible_decision_simulator/game_engine/stat/stat_state.dart';
import 'package:bible_decision_simulator/game_engine/stat/daily_trend_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _isDailyTrendEnabled = false;

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({
    super.key,
    required this.stats,
    required this.streak,
    required this.highestStreak,
    required this.endingSummary,
    required this.scenes,
    required this.currentSceneId,
    required this.onOpenSceneByIndex,
    required this.text,
    this.dailyTrend,
    this.onNavigateScenarioView,
    this.onDebugOpenSceneByIndex,
  });

  final StatState stats;
  final int streak;
  final int highestStreak;
  final String endingSummary;
  final List<Scene> scenes;
  final String? currentSceneId;
  final Future<bool> Function(int index) onOpenSceneByIndex;
  final UiText text;
  final DailyTrend? dailyTrend;
  final VoidCallback? onNavigateScenarioView;
  final Future<bool> Function(int index)? onDebugOpenSceneByIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canShowDonate = ref.watch(monetizationConfigProvider).maybeWhen(
          data: (config) =>
              config.enableDonate && highestStreak >= config.donateMinStreak,
          orElse: () => false,
        );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(text.daySummary,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_fire_department_outlined),
              title: Text(text.currentStreak),
              subtitle: Text(text.dayCount(streak)),
            ),
          ),
          if (scenes.isNotEmpty && endingSummary.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(text.endingSummary(endingSummary)),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ListView(
                  children: _orderedStatKeys
                      .map(
                        (key) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(text.statLabel(key)),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                  value: _statValue(key) / 100),
                              const SizedBox(height: 2),
                              Text('${_statValue(key)}/100'),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
          if (_isDailyTrendEnabled && dailyTrend != null) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.dailyTrend,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._orderedStatKeys.map(
                      (key) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _TrendRow(
                          label: text.statLabel(key),
                          direction: dailyTrend!.directions[key] ??
                              TrendDirection.stable,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _openSituation(context),
              child: Text(text.situation),
            ),
          ),
          if (canShowDonate) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => const DonateDialog(),
                  );
                },
                child: Text(text.donate),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _statValue(String key) => switch (key) {
        'faith' => stats.faith,
        'love' => stats.love,
        'humility' => stats.humility,
        'wisdom' => stats.wisdom,
        'pride' => stats.pride,
        _ => 50,
      };

  Future<void> _openSituation(BuildContext context) async {
    if (scenes.isEmpty) {
      onNavigateScenarioView?.call();
      return;
    }
    if (kDebugMode && onDebugOpenSceneByIndex != null) {
      final opened = await _openDebugSituation(context);
      if (opened) {
        onNavigateScenarioView?.call();
      }
      return;
    }
    final currentIndex =
        scenes.indexWhere((scene) => scene.id == currentSceneId);
    if (currentIndex >= 0 && currentIndex < scenes.length) {
      await onOpenSceneByIndex(currentIndex);
      onNavigateScenarioView?.call();
      return;
    }

    if (!context.mounted) return;
    final selectedIndex = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(text.selectSituation),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: scenes.length,
            itemBuilder: (itemContext, index) => ListTile(
              title: Text(scenes[index].title),
              onTap: () => Navigator.of(dialogContext).pop(index),
            ),
          ),
        ),
      ),
    );
    if (selectedIndex == null) return;
    await onOpenSceneByIndex(selectedIndex);
    onNavigateScenarioView?.call();
  }

  Future<bool> _openDebugSituation(BuildContext context) async {
    final currentIndex =
        scenes.indexWhere((scene) => scene.id == currentSceneId);
    final selectedIndex = await _showScenePickerDialog(context);
    if (selectedIndex == null) return false;

    var targetIndex = selectedIndex;
    if (selectedIndex == _debugOpenNextSentinelIndex) {
      targetIndex =
          currentIndex < 0 ? 0 : (currentIndex + 1) % scenes.length;
    }

    final openedNormally = await onOpenSceneByIndex(targetIndex);
    if (openedNormally) return true;
    return await onDebugOpenSceneByIndex!(targetIndex);
  }

  Future<int?> _showScenePickerDialog(BuildContext context) async {
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(text.selectSituation),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: scenes.length + 1,
            itemBuilder: (itemContext, index) {
              if (index == 0) {
                return ListTile(
                  leading: const Icon(Icons.skip_next),
                  title: const Text('Debug: open next scene'),
                  onTap: () => Navigator.of(dialogContext)
                      .pop(_debugOpenNextSentinelIndex),
                );
              }
              final sceneIndex = index - 1;
              return ListTile(
                title: Text(scenes[sceneIndex].title),
                onTap: () => Navigator.of(dialogContext).pop(sceneIndex),
              );
            },
          ),
        ),
      ),
    );
  }
}

const _orderedStatKeys = ['faith', 'love', 'humility', 'wisdom', 'pride'];
const _debugOpenNextSentinelIndex = -1;

class _TrendRow extends StatelessWidget {
  const _TrendRow({
    required this.label,
    required this.direction,
  });

  final String label;
  final TrendDirection direction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (direction) {
      TrendDirection.up => ('↑', Colors.green),
      TrendDirection.down => ('↓', colorScheme.error),
      TrendDirection.stable => ('→', Colors.grey),
    };

    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          icon,
          style:
              Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

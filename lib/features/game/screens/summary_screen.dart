import 'package:bible_decision_simulator/core/i18n.dart';
import 'package:bible_decision_simulator/features/monetization/donate_dialog.dart';
import 'package:bible_decision_simulator/game_engine/models/content_models.dart';
import 'package:bible_decision_simulator/game_engine/stat/stat_state.dart';
import 'package:bible_decision_simulator/game_engine/stat/daily_trend_engine.dart';
import 'package:flutter/material.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({
    super.key,
    required this.stats,
    required this.streak,
    required this.endingSummary,
    required this.scenes,
    required this.currentSceneId,
    required this.onOpenSceneByIndex,
    required this.text,
    this.dailyTrend,
    this.onNavigateScenarioView,
  });

  final StatState stats;
  final int streak;
  final String endingSummary;
  final List<Scene> scenes;
  final String? currentSceneId;
  final Future<bool> Function(int index) onOpenSceneByIndex;
  final UiText text;
  final DailyTrend? dailyTrend;
  final VoidCallback? onNavigateScenarioView;

  @override
  Widget build(BuildContext context) {
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
                  children: _orderedStatKeys.map(
                    (key) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(text.statLabel(key)),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(value: _statValue(key) / 100),
                          const SizedBox(height: 2),
                          Text('${_statValue(key)}/100'),
                        ],
                      ),
                    ),
                  ).toList(),
                ),
              ),
            ),
          ),
          if (dailyTrend != null) ...[
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
    if (scenes.isEmpty) return;
    final currentIndex =
        scenes.indexWhere((scene) => scene.id == currentSceneId);
    if (currentIndex >= 0 && currentIndex < scenes.length - 1) {
      final opened = await onOpenSceneByIndex(currentIndex + 1);
      if (opened) {
        onNavigateScenarioView?.call();
      }
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
    final opened = await onOpenSceneByIndex(selectedIndex);
    if (opened) {
      onNavigateScenarioView?.call();
    }
  }
}

const _orderedStatKeys = ['faith', 'love', 'humility', 'wisdom', 'pride'];

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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

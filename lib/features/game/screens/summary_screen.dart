import 'package:bible_decision_simulator/core/i18n.dart';
import 'package:bible_decision_simulator/features/monetization/donate_dialog.dart';
import 'package:bible_decision_simulator/game_engine/stat/stat_state.dart';
import 'package:bible_decision_simulator/game_engine/stat/daily_trend_engine.dart';
import 'package:flutter/material.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({
    super.key,
    required this.stats,
    required this.streak,
    required this.endingSummary,
    required this.onNextDay,
    required this.onToday,
    required this.canNextDay,
    required this.text,
    this.dailyTrend,
  });

  final StatState stats;
  final int streak;
  final String endingSummary;
  final VoidCallback onNextDay;
  final VoidCallback onToday;
  final bool canNextDay;
  final UiText text;
  final DailyTrend? dailyTrend;

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
              child: Text(endingSummary),
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
              onPressed: canNextDay ? onNextDay : null,
              child: Text(text.nextDay),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onToday,
              child: Text(text.today),
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

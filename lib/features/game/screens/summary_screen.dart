import 'package:bible_decision_simulator/core/i18n.dart';
import 'package:bible_decision_simulator/features/monetization/donate_dialog.dart';
import 'package:bible_decision_simulator/game_engine/models/game_state.dart';
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
  });

  final StatState stats;
  final int streak;
  final String endingSummary;
  final VoidCallback onNextDay;
  final VoidCallback onToday;
  final bool canNextDay;
  final UiText text;

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
                  children: GameStat.values.map((stat) {
                    final value = stats.valueOf(stat);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(text.statLabel(stat)),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(value: value / 100),
                          const SizedBox(height: 2),
                          Text('$value/100'),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
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
}

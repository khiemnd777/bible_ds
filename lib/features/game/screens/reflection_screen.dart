import 'package:bible_decision_simulator/core/i18n.dart';
import 'package:bible_decision_simulator/game_engine/models/content_models.dart';
import 'package:flutter/material.dart';

class ReflectionScreen extends StatelessWidget {
  const ReflectionScreen({
    super.key,
    required this.reflection,
    required this.onContinue,
    required this.text,
  });

  final ReflectionContent? reflection;
  final VoidCallback onContinue;
  final UiText text;

  @override
  Widget build(BuildContext context) {
    final data = reflection;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(text.reflection,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Expanded(
            child: data == null
                ? Center(child: Text(text.noReflectionAvailable))
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListView(
                        children: [
                          Text(data.verseRef,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            data.verseText,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 16),
                          Text(text.questions,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          ...data.questions.map((q) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text('• $q'),
                              )),
                        ],
                      ),
                    ),
                  ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onContinue,
              child: Text(text.continueText),
            ),
          ),
        ],
      ),
    );
  }
}

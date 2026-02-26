import 'package:bible_decision_simulator/core/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContentPreviewScreen extends ConsumerWidget {
  const ContentPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(contentPreviewControllerProvider);
    final controller = ref.read(contentPreviewControllerProvider.notifier);
    final text = ref.watch(uiTextProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text(state.error!));
    }

    final content = state.content;
    if (content == null) {
      return Center(child: Text(text.noContentLoaded));
    }

    final scene = state.selectedScene;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text(text.contentPreview,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: scene?.id,
            decoration: InputDecoration(
              labelText: text.scene,
              border: OutlineInputBorder(),
            ),
            items: content.scenes
                .map((s) => DropdownMenuItem(
                    value: s.id, child: Text('${s.id} - ${s.title}')))
                .toList(),
            onChanged: (value) {
              if (value != null) controller.selectScene(value);
            },
          ),
          const SizedBox(height: 16),
          if (scene != null) ...[
            Text(scene.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...scene.conversation.turns.map((turn) => Card(
                  child: ListTile(
                    title: Text(turn.speaker),
                    subtitle: Text(turn.text),
                  ),
                )),
            const SizedBox(height: 8),
            Text(text.simulateChoice,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...scene.initialChoices.map((choice) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: () => controller.simulateChoice(choice.id),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(choice.text),
                    ),
                  ),
                )),
          ],
          const SizedBox(height: 12),
          if (state.simulatedOutcome != null)
            Card(
              child: ListTile(
                title: Text(text.outcome),
                subtitle: Text(state.simulatedOutcome!),
              ),
            ),
          if (state.simulatedReflection != null)
            Card(
              child: ListTile(
                title: Text(state.simulatedReflection!.verseRef),
                subtitle: Text(state.simulatedReflection!.verseText),
              ),
            ),
          const SizedBox(height: 12),
          Text(text.validation, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (state.validationErrors.isEmpty)
            Card(
              child: ListTile(
                leading: Icon(Icons.check_circle_outline, color: Colors.green),
                title: Text(text.noValidationErrors),
              ),
            )
          else
            ...state.validationErrors.map(
              (e) => Card(
                child: ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  title: Text(e),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

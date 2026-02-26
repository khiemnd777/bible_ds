import 'package:flutter/material.dart';

class OutcomeScreen extends StatelessWidget {
  const OutcomeScreen({
    super.key,
    required this.title,
    required this.outcomeText,
    required this.onNext,
  });

  final String title;
  final String outcomeText;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    outcomeText,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class DonateDialog extends StatelessWidget {
  const DonateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Support the Project'),
      content: const Text(
        'Thank you for considering support. This is a scaffold dialog where payment integrations can be added later.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Donate'),
        ),
      ],
    );
  }
}

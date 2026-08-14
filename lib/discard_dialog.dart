import 'package:flutter/material.dart';

Future<bool> confirmDiscard(BuildContext context) async {
  final shouldDiscard = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Forkast bildene?'),
        content: const Text(
          'Bildene er ikke lagret. Hvis du går tilbake, forsvinner de.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Forkast'),
          ),
        ],
      );
    },
  );
  return shouldDiscard ?? false;
}

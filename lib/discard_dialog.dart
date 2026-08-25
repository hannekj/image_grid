import 'package:flutter/material.dart';

import 'app_copy.dart';

Future<bool> confirmDiscard(BuildContext context) async {
  final shouldDiscard = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(AppCopy.discardTitle),
        content: const Text(AppCopy.discardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppCopy.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppCopy.discard),
          ),
        ],
      );
    },
  );
  return shouldDiscard ?? false;
}

import 'package:flutter/material.dart';
import 'package:fauth/models/credential.dart';

Future<bool> showConfirmDeleteCredentialDialog(
  BuildContext context,
  Credential credential,
) async {
  final required = '${credential.rpId}/${credential.userName}';
  final controller = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Delete credential'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('To confirm, type "$required" in the box below.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type confirmation here',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: controller.text == required
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    },
  );

  return confirmed == true;
}

import 'package:fauth/models/credential.dart';
import 'package:flutter/material.dart';

class CredentialListPage extends StatelessWidget {
  final List<Credential> credentials;
  final ValueChanged<Credential>? onDelete;

  const CredentialListPage({
    super.key,
    required this.credentials,
    this.onDelete,
  });

  Future<bool> _deleteConfirmation(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Credentials')),
      body: ListView.builder(
        itemCount: credentials.length,
        itemBuilder: (context, index) {
          final credential = credentials[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: const Icon(Icons.vpn_key),
              title: Text(credential.rpId),
              subtitle: Text(credential.userName),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirmed = await _deleteConfirmation(
                    context,
                    credential,
                  );

                  if (confirmed) {
                    if (!context.mounted) return;

                    onDelete?.call(credential);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Credential deleted')),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

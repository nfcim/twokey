import 'package:fauth/models/credential.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fauth/viewmodels/keys_viewmodel.dart';

class CredentialListPage extends StatelessWidget {
  const CredentialListPage({super.key});

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
    return Consumer<KeysViewModel>(
      builder: (context, vm, _) {
        final list = vm.credentials;
        return Scaffold(
          appBar: AppBar(title: const Text('Credentials')),
          body: list.isEmpty
              ? const Center(child: Text('No credentials'))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final credential = list[index];
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
                            if (!confirmed) return;
                            if (!context.mounted) return;
                            final ok = await vm.deleteCredentialByModel(
                              credential,
                            );
                            if (!context.mounted) return;
                            if (ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Credential deleted'),
                                ),
                              );
                            } else if (vm.errorMessage != null &&
                                !vm.pinRequired) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Delete failed: ${vm.errorMessage}',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

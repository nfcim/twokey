import 'package:fauth/models/credential.dart';
import 'package:flutter/material.dart';

class CredentialListPage extends StatelessWidget {
  final List<Credential> credentials;

  const CredentialListPage({super.key, required this.credentials});

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
                onPressed: () {
                  // TODO: Implement delete credential functionality
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

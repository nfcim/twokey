import 'package:fauth/viewmodels/keys_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class KeysPage extends StatelessWidget {
  const KeysPage({super.key});

  @override
  Widget build(BuildContext context) {
    var viewModel = Provider.of<KeysViewModel>(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (viewModel.isLoading) const CircularProgressIndicator(),
            if (viewModel.authenticatorInfo != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SelectableText(
                  'AAGUID: ${viewModel.authenticatorInfo!.aaguid.map((e) => e.toRadixString(16).padLeft(2, '0')).join('')}\n'
                  'Versions: ${viewModel.authenticatorInfo!.versions.join(', ')}\n'
                  'Extensions: ${viewModel.authenticatorInfo!.extensions?.join(', ') ?? 'N/A'}',
                  textAlign: TextAlign.center,
                ),
              ),
            if (viewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SelectableText(
                  'Error: ${viewModel.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton(
              onPressed: viewModel.isLoading
                  ? null
                  : viewModel.fetchAuthenticatorInfo,
              child: const Text('Authenticator Info'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:fauth/pages/credential_list.dart';
import 'package:fauth/viewmodels/keys_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class KeysPage extends StatefulWidget {
  const KeysPage({super.key});

  @override
  State<KeysPage> createState() => _KeysPageState();
}

class _KeysPageState extends State<KeysPage> {
  final _pinController = TextEditingController();
  bool _pinDialogOpen = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _ensurePin(KeysViewModel vm) async {
    if (!vm.pinRequired || _pinDialogOpen) return;
    _pinDialogOpen = true;
    await Future.delayed(Duration.zero); // ensure frame
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Please input you PIN:'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _pinController,
              autofocus: true,
              obscureText: true,
              maxLength: 63,
              decoration: const InputDecoration(
                labelText: 'PIN',
                counterText: '',
              ),
              onSubmitted: (_) => _submitPin(vm),
            ),
            if (vm.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  vm.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pinDialogOpen = false;
            },
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => _submitPin(vm),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    _pinDialogOpen = false;
  }

  void _submitPin(KeysViewModel vm) {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;
    vm.submitPin(pin);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KeysViewModel>(
      builder: (_, vm, __) {
        // If view model signals pin required, show dialog.
        if (vm.pinRequired) {
          _ensurePin(vm); // fire and forget
        }
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (vm.isLoading) const CircularProgressIndicator(),
                if (vm.authenticatorInfo != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SelectableText(
                      [
                        'AAGUID: ${vm.authenticatorInfo!.aaguid.map((e) => e.toRadixString(16).padLeft(2, '0')).join('')}',
                        'Versions: ${vm.authenticatorInfo!.versions.join(', ')}',
                        'Extensions: ${vm.authenticatorInfo!.extensions?.join(', ') ?? 'N/A'}',
                      ].join('\n'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (vm.errorMessage != null && !vm.pinRequired)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SelectableText(
                      'Error: ${vm.errorMessage}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ElevatedButton(
                  onPressed: vm.isLoading
                      ? null
                      : () async {
                          await vm.fetchAuthenticatorInfo();
                        },
                  child: const Text('Authenticator Info'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: vm.isLoading
                      ? null
                      : () async {
                          final ok = await vm.fetchCredentials();
                          if (!ok) return; // waiting for PIN / failure
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CredentialListPage(),
                            ),
                          );
                        },
                  child: const Text('List Credentials'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fauth/viewmodels/keys_viewmodel.dart';
import 'package:provider/provider.dart';

class DeveloperToolsSection extends StatelessWidget {
  const DeveloperToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KeysViewModel>();
    return ExpansionTile(
      leading: const Icon(Icons.science_outlined),
      title: const Text('Developer Tools (Test Register / Verify)'),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: vm.isLoading
                  ? null
                  : () async {
                      try {
                        final ok = await vm.testRegister(
                          username: 'test-user',
                          displayName: 'Test User',
                        );
                        if (!context.mounted) return;
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test register succeeded'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test register failed'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Test register error: $e')),
                        );
                      }
                    },
              child: const Text('Test Register'),
            ),
            ElevatedButton(
              onPressed: vm.isLoading
                  ? null
                  : () async {
                      try {
                        final ok = await vm.testVerify();
                        if (!context.mounted) return;
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test verify succeeded'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Test verify failed')),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Test verify error: $e')),
                        );
                      }
                    },
              child: const Text('Test Verify'),
            ),
          ],
        ),
      ],
    );
  }
}

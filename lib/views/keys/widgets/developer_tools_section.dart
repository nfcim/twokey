import 'package:fauth/widgets/card.dart';
import 'package:flutter/material.dart';
import 'package:fauth/viewmodels/keys_viewmodel.dart';
import 'package:provider/provider.dart';

class DeveloperToolsSection extends StatelessWidget {
  const DeveloperToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KeysViewModel>();
    return CommonCard(
      onPressed: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(
                  Icons.science_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Developer Tools',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                TextButton(
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
                              SnackBar(
                                content: Text('Test register error: $e'),
                              ),
                            );
                          }
                        },
                  child: const Text('Test Register'),
                ),
                TextButton(
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
                                const SnackBar(
                                  content: Text('Test verify failed'),
                                ),
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
          ),
        ],
      ),
    );
  }
}

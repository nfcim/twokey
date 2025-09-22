import 'package:flutter/material.dart';
import 'package:flkey/viewmodels/keys_viewmodel.dart';
import 'package:flkey/models/credential.dart';
import 'package:provider/provider.dart';
import '../dialogs/confirm_delete_credential.dart';
import 'package:flkey/widgets/card.dart';
import 'package:flkey/common/context.dart';

class CredentialsSection extends StatelessWidget {
  const CredentialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KeysViewModel>();
    return CommonCard(
      onPressed: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Row(
              children: [
                Icon(
                  Icons.vpn_key,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Credentials',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: vm.isLoading
                      ? null
                      : () async {
                          await vm.fetchCredentials();
                        },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vm.isLoading && vm.credentials.isEmpty)
                  const LinearProgressIndicator(),
                if (vm.credentials.isEmpty && !vm.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: Text('No credentials')),
                  )
                else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: vm.credentials.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final credential = vm.credentials[index];
                      return _CredentialTile(credential: credential);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialTile extends StatelessWidget {
  final Credential credential;
  const _CredentialTile({required this.credential});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<KeysViewModel>();
    return ListTile(
      title: Text(credential.rpId),
      subtitle: Text(credential.userName),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: vm.isLoading
            ? null
            : () async {
                final confirmed = await showConfirmDeleteCredentialDialog(
                  context,
                  credential,
                );
                if (!confirmed) return;
                final ok = await vm.deleteCredentialByModel(credential);
                if (!context.mounted) return;
                if (ok) {
                  await context.showNotifier('Credential deleted');
                } else if (vm.errorMessage != null && !vm.pinRequired) {
                  await context.showNotifier(
                    'Delete failed: ${vm.errorMessage}',
                  );
                }
              },
      ),
    );
  }
}

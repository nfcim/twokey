import 'package:flutter/material.dart';
import 'package:fauth/viewmodels/keys_viewmodel.dart';
import 'package:provider/provider.dart';
import 'kv_row.dart';
import 'package:fauth/widgets/card.dart';

class DeviceInfoSection extends StatelessWidget {
  const DeviceInfoSection({super.key});

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
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Device Info',
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
            padding: const EdgeInsets.fromLTRB(32, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vm.authenticatorInfo == null && vm.isLoading)
                  const LinearProgressIndicator(),
                if (vm.authenticatorInfo != null) ...[
                  KvRow(
                    label: 'AAGUID',
                    value: vm.authenticatorInfo!.aaguid
                        .map((e) => e.toRadixString(16).padLeft(2, '0'))
                        .join(''),
                  ),
                  KvRow(
                    label: 'Versions',
                    value: vm.authenticatorInfo!.versions.join(', '),
                  ),
                  KvRow(
                    label: 'Extensions',
                    value:
                        vm.authenticatorInfo!.extensions?.join(', ') ?? 'N/A',
                  ),
                ] else if (!vm.isLoading) ...[
                  const Text(
                    'No device info. Check connection and reopen this page.',
                    style: TextStyle(fontSize: 12),
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

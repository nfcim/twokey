import 'package:flutter/material.dart';
import 'package:fauth/viewmodels/keys_viewmodel.dart';
import 'package:provider/provider.dart';
import 'kv_row.dart';

class DeviceInfoSection extends StatelessWidget {
  const DeviceInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KeysViewModel>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.usb, size: 20),
                SizedBox(width: 8),
                Text(
                  'Device Info',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
                value: vm.authenticatorInfo!.extensions?.join(', ') ?? 'N/A',
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
    );
  }
}

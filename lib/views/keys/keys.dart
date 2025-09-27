import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twokey/viewmodels/keys.dart';
import 'package:twokey/api/unified_fido_api.dart';
import 'widgets/device_info_section.dart';
import 'widgets/credentials_section.dart';
import 'widgets/developer_tools_section.dart';
import 'package:twokey/common/context.dart';

class KeysPage extends StatefulWidget {
  const KeysPage({super.key});

  @override
  State<KeysPage> createState() => _KeysPageState();
}

class _KeysPageState extends State<KeysPage> {
  final _pinController = TextEditingController();
  bool _pinDialogOpen = false;
  bool _deviceSelectionDialogOpen = false;
  bool _wasWaitingForTouch = false;
  String? _lastErrorShown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final vm = context.read<KeysViewModel>();
      // Do not auto-load on entry; instead, prompt device selection first
      await vm.refreshAvailableDevices();
      if (vm.selectedDevice == null) {
        vm.requestDeviceSelection();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _ensureDeviceSelection(KeysViewModel vm) async {
    if (!vm.deviceSelectionRequired || _deviceSelectionDialogOpen) return;
    _deviceSelectionDialogOpen = true;
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Select FIDO2 Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Please choose a key to use (CCID or NFC).'),
                ),
                IconButton(
                  onPressed: () async {
                    // Refresh device list
                    await vm.refreshAvailableDevices();
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh device list',
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...vm.availableDevices.map(
              (device) => ListTile(
                leading: Icon(
                  device.type == FidoDeviceType.ccid ? Icons.usb : Icons.nfc,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(device.name),
                subtitle: Text(device.description),
                onTap: () {
                  vm.submitDeviceSelection(device);
                  Navigator.of(context).pop();
                },
              ),
            ),
            if (vm.availableDevices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No keys detected. Connect a CCID reader or enable NFC, then refresh.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            if (vm.errorMessage != null) const SizedBox(height: 8),
            if (vm.errorMessage != null)
              Text(
                vm.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              vm.cancelDeviceSelection();
              Navigator.of(context).pop();
              _deviceSelectionDialogOpen = false;
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    // After dialog closes, if a device was selected, explicitly load data now
    if (vm.selectedDevice != null) {
      await vm.ensureLoaded();
    }
    _deviceSelectionDialogOpen = false;
  }

  Future<void> _ensurePin(KeysViewModel vm) async {
    if (!vm.pinRequired || _pinDialogOpen) return;
    _pinDialogOpen = true;
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Please input your PIN:'),
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
            if (vm.errorMessage != null) const SizedBox(height: 8),
            if (vm.errorMessage != null)
              Text(
                vm.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              vm.cancelPinRequest();
              Navigator.of(context).pop();
              _pinDialogOpen = false;
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _submitPin(vm),
            child: const Text('Confirm'),
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
        if (vm.pinRequired) {
          _ensurePin(vm);
        }
        if (vm.deviceSelectionRequired) {
          _ensureDeviceSelection(vm);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          if (vm.waitingForTouch && !_wasWaitingForTouch) {
            _wasWaitingForTouch = true;
            await context.showNotifier(
              'Please complete verification on your security key (e.g. touch or fingerprint)',
            );
          } else if (!vm.waitingForTouch && _wasWaitingForTouch) {
            _wasWaitingForTouch = false;
          }

          if (vm.errorMessage != null &&
              !vm.pinRequired &&
              vm.errorMessage != _lastErrorShown) {
            _lastErrorShown = vm.errorMessage;
            await context.showNotifier(
              vm.errorMessage!,
              backgroundColor: Theme.of(context).colorScheme.error,
            );
          }
        });
        final noDevices = vm.availableDevices.isEmpty;
        final hasSelection = vm.selectedDevice != null;
        return Scaffold(
          appBar: AppBar(title: const Text('WebAuthn')),
          body: SafeArea(
            child: noDevices
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No FIDO2 devices found. Please ensure your key is connected or near the device.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                : hasSelection
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      DeviceInfoSection(),
                      SizedBox(height: 16),
                      CredentialsSection(),
                      SizedBox(height: 16),
                      DeveloperToolsSection(),
                    ],
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Please choose a key from the dialog to continue.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
          ),
          floatingActionButton: noDevices
              ? IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: vm.isLoading
                      ? null
                      : () async {
                          await vm.refreshAvailableDevices();
                        },
                  tooltip: 'Refresh',
                )
              : (!hasSelection ? null : null),
        );
      },
    );
  }
}

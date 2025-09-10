import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fauth/viewmodels/keys_viewmodel.dart';

class KeysSnackbarListener extends StatefulWidget {
  final Widget child;
  const KeysSnackbarListener({super.key, required this.child});

  @override
  State<KeysSnackbarListener> createState() => _KeysSnackbarListenerState();
}

class _KeysSnackbarListenerState extends State<KeysSnackbarListener> {
  bool _wasWaitingForTouch = false;
  String? _lastErrorShown;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KeysViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (vm.waitingForTouch && !_wasWaitingForTouch) {
        _wasWaitingForTouch = true;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('请在安全密钥上完成验证（如按下指纹/触摸按键）'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(days: 1),
          ),
        );
      } else if (!vm.waitingForTouch && _wasWaitingForTouch) {
        _wasWaitingForTouch = false;
        messenger.hideCurrentSnackBar();
      }

      if (vm.errorMessage != null &&
          !vm.pinRequired &&
          vm.errorMessage != _lastErrorShown) {
        _lastErrorShown = vm.errorMessage;
        messenger.showSnackBar(
          SnackBar(
            content: Text('错误：${vm.errorMessage}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return widget.child;
  }
}

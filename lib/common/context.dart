import 'package:flutter/material.dart';
import 'package:twokey/widgets/notifier.dart';

extension BuildContextExtension on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;

  Future<void> showNotifier(
    String message, {
    Duration? duration,
    Color? backgroundColor,
  }) async {
    await Notifier.instance.show(
      message,
      duration: duration,
      backgroundColor: backgroundColor,
    );
  }
}

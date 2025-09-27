import 'dart:io';

bool isDesktop() => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

bool isMobile() => Platform.isAndroid || Platform.isIOS;

bool isWeb() =>
    identical(0, 0.0); // This is a common way to detect web platform in Dart

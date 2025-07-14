import 'dart:io';
import 'system.dart' as system;

const appName = 'FAuth';
final double titleBarHeight = system.isDesktop()
    ? !Platform.isMacOS
          ? 40
          : 28
    : 0;

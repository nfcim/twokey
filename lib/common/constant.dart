import 'dart:io';
import 'package:fauth/common/system.dart' as system;

const appName = 'FAuth';
final double titleBarHeight = system.isDesktop()
    ? !Platform.isMacOS
          ? 40
          : 28
    : 0;

import 'package:twokey/api/ccid_fido_api.dart';
import 'package:twokey/repositories/credential_repository.dart';
import 'package:twokey/viewmodels/keys_viewmodel.dart';
import 'package:twokey/viewmodels/navigation_viewmodel.dart';
import 'package:twokey/viewmodels/log_viewmodel.dart';
import 'package:twokey/viewmodels/theme_viewmodel.dart';
import 'package:twokey/common/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:twokey/common/system.dart' as system;
import 'package:twokey/views/home.dart';
import 'package:twokey/widgets/notifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (system.isDesktop()) {
    windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(400, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      // titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => KeysViewModel(CredentialRepository(CcidFidoApi())),
        ),
        ChangeNotifierProvider(create: (_) => NavigationViewModel()),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => LogViewModel(AppLogger.stream),
        ),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeVm = Provider.of<ThemeViewModel>(context);
    return MaterialApp(
      title: 'TwoKey',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: themeVm.themeMode,
      builder: (context, child) => NotifierHost(
        key: Notifier.hostKey,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const HomePage(),
    );
  }
}

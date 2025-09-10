import 'package:fauth/api/ccid_fido_api.dart';
import 'package:fauth/repositories/credential_repository.dart';
import 'package:fauth/viewmodels/keys_viewmodel.dart';
import 'package:fauth/viewmodels/navigation_viewmodel.dart';
import 'package:fauth/viewmodels/log_viewmodel.dart';
import 'package:fauth/common/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:fauth/common/system.dart' as system;
import 'package:fauth/views/home.dart';

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
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FAuth',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const HomePage(),
    );
  }
}

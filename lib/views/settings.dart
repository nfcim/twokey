import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flkey/viewmodels/theme_viewmodel.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeVm = context.watch<ThemeViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark mode'),
            value: themeVm.isDark,
            onChanged: (value) => themeVm.toggleDark(value),
          ),
          ListTile(
            title: const Text('About'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'FlKey',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 inuEbisu',
              );
            },
          ),
        ],
      ),
    );
  }
}

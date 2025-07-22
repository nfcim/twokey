import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  String _language = '简体中文';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('深色模式'),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
            },
          ),
          ListTile(
            title: const Text('语言'),
            trailing: DropdownButton<String>(
              value: _language,
              items: const [
                DropdownMenuItem(value: '简体中文', child: Text('简体中文')),
                DropdownMenuItem(value: 'English', child: Text('English')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                  });
                }
              },
            ),
          ),
          ListTile(
            title: const Text('关于'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'FAuth',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 inuEbisu',
              );
            },
          ),
          ListTile(
            title: const Text('Test setting 1'),
            subtitle: const Text('Subtitle'),
          ),
          ListTile(title: const Text('Test setting 2')),
          ListTile(title: const Text('Test setting 3')),
          ListTile(title: const Text('Test setting 4')),
          ListTile(title: const Text('Test setting 5')),
          ListTile(title: const Text('Test setting 6')),
          ListTile(title: const Text('Test setting 7')),
          ListTile(title: const Text('Test setting 8')),
          ListTile(title: const Text('Test setting 9')),
        ],
      ),
    );
  }
}

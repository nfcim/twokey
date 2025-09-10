import 'package:fauth/views/keys/keys_page.dart';
import 'package:fauth/views/settings/settings_page.dart';
import 'package:fauth/viewmodels/navigation_viewmodel.dart';
import 'package:fauth/views/home/widgets/adaptive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationViewModel>();
    final page = _pageFor(nav.selectedIndex);

    return AdaptiveScaffold(
      items: const [
        NavItem(icon: Icons.key, label: 'WebAuthn'),
        NavItem(icon: Icons.settings, label: 'Settings'),
      ],
      selectedIndex: nav.selectedIndex,
      onSelected: nav.select,
      body: page,
    );
  }

  Widget _pageFor(int index) {
    switch (index) {
      case 0:
        return const KeysPage();
      case 1:
        return SettingsPage();
      default:
        return const Center(child: Text('Page not implemented'));
    }
  }
}

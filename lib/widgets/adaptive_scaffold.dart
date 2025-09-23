import 'package:flutter/material.dart';
import 'package:twokey/common/context.dart';

class NavItem {
  final IconData icon;
  final String label;
  const NavItem({required this.icon, required this.label});
}

/// A small responsive scaffold that switches between BottomNavigationBar
/// and NavigationRail based on available width.
class AdaptiveScaffold extends StatelessWidget {
  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget body;
  final double railExtendedMinWidth;
  final double bottomNavMaxWidth;

  const AdaptiveScaffold({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.body,
    this.railExtendedMinWidth = 960,
    this.bottomNavMaxWidth = 640,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < bottomNavMaxWidth) {
          return Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: body,
                  ),
                ),
                SafeArea(
                  child: NavigationBar(
                    destinations: [
                      for (final it in items)
                        NavigationDestination(
                          icon: Icon(it.icon),
                          label: it.label,
                        ),
                    ],
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onSelected,
                  ),
                ),
              ],
            ),
          );
        }

        final railExtended = constraints.maxWidth >= railExtendedMinWidth;
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  backgroundColor: context.colorScheme.surfaceContainer,
                  extended: railExtended,
                  destinations: [
                    for (final it in items)
                      NavigationRailDestination(
                        icon: Icon(it.icon),
                        label: Text(it.label),
                      ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onSelected,
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: body,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

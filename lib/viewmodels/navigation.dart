import 'package:flutter/foundation.dart';

/// Holds and manages the app's top-level navigation state.
class NavigationViewModel extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void select(int index) {
    if (index == _selectedIndex) return;
    _selectedIndex = index;
    notifyListeners();
  }
}

import 'package:twokey/viewmodels/navigation_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NavigationViewModel', () {
    test('initial index is 0 and notifies on change', () {
      final vm = NavigationViewModel();
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      expect(vm.selectedIndex, 0);

      vm.select(1);
      expect(vm.selectedIndex, 1);
      expect(notifyCount, 1);

      // Selecting the same index should not notify again.
      vm.select(1);
      expect(vm.selectedIndex, 1);
      expect(notifyCount, 1);
    });
  });
}

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:twokey/main.dart';
import 'package:twokey/viewmodels/navigation_viewmodel.dart';
import 'package:twokey/widgets/adaptive_scaffold.dart';

void main() {
  testWidgets('App renders HomePage with navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) {
          final nav = NavigationViewModel();
          nav.select(1);
          return nav;
        },
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(AdaptiveScaffold), findsOneWidget);

    expect(find.text('Settings'), findsWidgets);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtualwalker/constants/strings.dart';
import 'package:virtualwalker/main.dart';

void main() {
  group('VirtualWalkerApp', () {
    testWidgets('renders app title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: VirtualWalkerApp()),
      );

      expect(find.text(AppStrings.appName), findsOneWidget);
    });

    testWidgets('uses Material3 theme', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: VirtualWalkerApp()),
      );

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.useMaterial3, isTrue);
    });

    testWidgets('wraps content in a Scaffold', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: VirtualWalkerApp()),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}

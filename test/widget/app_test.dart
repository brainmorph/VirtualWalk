import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtualwalker/main.dart';
import 'package:virtualwalker/screens/map_screen.dart';

void main() {
  group('VirtualWalkerApp', () {
    testWidgets('uses Material3 theme', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: VirtualWalkerApp()),
      );

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.useMaterial3, isTrue);
    });

    testWidgets('home is MapScreen', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: VirtualWalkerApp()),
      );

      expect(find.byType(MapScreen), findsOneWidget);
    });

    testWidgets('contains a FlutterMap', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: VirtualWalkerApp()),
      );

      expect(find.byType(FlutterMap), findsOneWidget);
    });
  });
}

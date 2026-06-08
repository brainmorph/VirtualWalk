import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtualwalker/screens/map_screen.dart';

void main() {
  group('MapScreen', () {
    testWidgets('renders a FlutterMap', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: _TestApp()),
      );

      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('includes a TileLayer', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: _TestApp()),
      );

      expect(find.byType(TileLayer), findsOneWidget);
    });

    testWidgets('includes RichAttributionWidget', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: _TestApp()),
      );

      expect(find.byType(RichAttributionWidget), findsOneWidget);
    });
  });
}

// Minimal app wrapper so MapScreen has MaterialApp + MediaQuery context.
class _TestApp extends StatelessWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MapScreen());
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:virtualwalker/providers/location_provider.dart';
import 'package:virtualwalker/screens/map_screen.dart';

// A Position with only the fields we care about for tests.
Position _fakePosition(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2024),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  group('MapScreen', () {
    testWidgets('renders a FlutterMap', (tester) async {
      await tester.pumpWidget(_buildApp(_loadingStream()));
      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('includes a TileLayer', (tester) async {
      await tester.pumpWidget(_buildApp(_loadingStream()));
      expect(find.byType(TileLayer), findsOneWidget);
    });

    testWidgets('includes RichAttributionWidget', (tester) async {
      await tester.pumpWidget(_buildApp(_loadingStream()));
      expect(find.byType(RichAttributionWidget), findsOneWidget);
    });

    testWidgets('shows loading indicator before first GPS fix', (tester) async {
      await tester.pumpWidget(_buildApp(_loadingStream()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides loading indicator after GPS fix', (tester) async {
      final position = _fakePosition(37.7749, -122.4194);
      await tester.pumpWidget(_buildApp(_positionStream(position)));
      await tester.pump(); // allow stream to emit
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows CircleLayer after GPS fix', (tester) async {
      final position = _fakePosition(37.7749, -122.4194);
      await tester.pumpWidget(_buildApp(_positionStream(position)));
      await tester.pump();
      expect(find.byType(CircleLayer), findsOneWidget);
    });
  });
}

// Helpers

Widget _buildApp(Stream<Position> stream) {
  return ProviderScope(
    overrides: [
      locationStreamProvider.overrideWith((_) => stream),
    ],
    child: const MaterialApp(home: MapScreen()),
  );
}

Stream<Position> _loadingStream() => const Stream.empty();

Stream<Position> _positionStream(Position p) => Stream.value(p);
